#!/usr/bin/env bash
# レベル4 差分キット: レベル3 の構築済み環境の上に WordPress 本番構成を追加する
# 前提: ../../03-ha-three-tier/handson/build.sh が完了し、.handson-state.env が存在すること
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
L3_STATE="${SCRIPT_DIR}/../../03-ha-three-tier/handson/.handson-state.env"
STATE_FILE="${SCRIPT_DIR}/.handson-state.env"
POLICY_DIR="${SCRIPT_DIR}/policies"

# ---- 利用者が調整する変数 -------------------------------------------------------
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-northeast-1}"
PREFIX="${PREFIX:-wp-prod}"
ALERT_EMAIL="${ALERT_EMAIL:?ALERT_EMAIL(通知先メールアドレス)を環境変数で指定してください}"
SECRET_NAME="${SECRET_NAME:-wordpress/prod/db}"
WP_DB_NAME="${WP_DB_NAME:-wordpress}"
CACHE_NODE_TYPE="${CACHE_NODE_TYPE:-cache.t3.micro}"

# ---- レベル3 の state を読み込む ------------------------------------------------
if [[ ! -f "${L3_STATE}" ]]; then
  echo "ERROR: レベル3 の state ファイルが見つかりません: ${L3_STATE}" >&2
  echo "       先に ../../03-ha-three-tier/handson/build.sh を実行してください。" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${L3_STATE}"

# レベル3 キット(../../03-ha-three-tier/handson/build.sh)が保存する変数名に読み替える
PRIVATE_DB_SUBNET_1A_ID="${PRIVATE_DB_SUBNET_1A_ID:-${SUBNET_DB_A:-}}"
PRIVATE_DB_SUBNET_1C_ID="${PRIVATE_DB_SUBNET_1C_ID:-${SUBNET_DB_C:-}}"
LAUNCH_TEMPLATE_ID="${LAUNCH_TEMPLATE_ID:-${LT_ID:-}}"
RDS_INSTANCE_ID="${RDS_INSTANCE_ID:-${DB_IDENTIFIER:-}}"

# 必要な変数が揃っているか確認する
for v in VPC_ID PRIVATE_DB_SUBNET_1A_ID PRIVATE_DB_SUBNET_1C_ID APP_SG_ID \
         ALB_ARN ASG_NAME LAUNCH_TEMPLATE_ID RDS_INSTANCE_ID RDS_ENDPOINT DB_USERNAME; do
  if [[ -z "${!v:-}" ]]; then
    echo "ERROR: レベル3 state に ${v} がありません。変数名を確認してください。" >&2
    exit 1
  fi
done
DB_PASSWORD="${DB_PASSWORD:?レベル3 state または環境変数で DB_PASSWORD を指定してください(RDS 管理パスワードの場合はコンソールで確認)}"

save_state() { echo "$1=\"$2\"" >> "${STATE_FILE}"; }
: > "${STATE_FILE}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "== アカウント ${ACCOUNT_ID} / リージョン ${AWS_DEFAULT_REGION} で構築を開始します =="

# ---- 1. Secrets Manager: DB 認証情報 ---------------------------------------------
echo "[1/8] Secrets Manager にシークレット ${SECRET_NAME} を作成"
SECRET_STRING=$(printf '{"username":"%s","password":"%s","host":"%s","dbname":"%s"}' \
  "${DB_USERNAME}" "${DB_PASSWORD}" "${RDS_ENDPOINT}" "${WP_DB_NAME}")
SECRET_ARN=$(aws secretsmanager create-secret \
  --name "${SECRET_NAME}" \
  --description "WordPress DB credentials (level4 handson)" \
  --secret-string "${SECRET_STRING}" \
  --query ARN --output text)
save_state SECRET_NAME "${SECRET_NAME}"
save_state SECRET_ARN "${SECRET_ARN}"

# ---- 2. S3: メディア用バケット(パブリックアクセスブロック維持) ------------------
echo "[2/8] S3 メディアバケットを作成"
MEDIA_BUCKET="${PREFIX}-media-${ACCOUNT_ID}"
aws s3api create-bucket \
  --bucket "${MEDIA_BUCKET}" \
  --create-bucket-configuration "LocationConstraint=${AWS_DEFAULT_REGION}"
aws s3api put-public-access-block \
  --bucket "${MEDIA_BUCKET}" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
save_state MEDIA_BUCKET "${MEDIA_BUCKET}"

# ---- 3. IAM: EC2 用ロール + インスタンスプロファイル -------------------------------
echo "[3/8] EC2 用 IAM ロールとインスタンスプロファイルを作成"
EC2_ROLE_NAME="${PREFIX}-ec2-role"
aws iam create-role \
  --role-name "${EC2_ROLE_NAME}" \
  --assume-role-policy-document "file://${POLICY_DIR}/ec2-trust-policy.json" > /dev/null
aws iam put-role-policy \
  --role-name "${EC2_ROLE_NAME}" \
  --policy-name "${PREFIX}-secrets-read" \
  --policy-document "$(sed "s#__SECRET_ARN__#${SECRET_ARN}#g" "${POLICY_DIR}/secrets-read-policy.template.json")"
aws iam put-role-policy \
  --role-name "${EC2_ROLE_NAME}" \
  --policy-name "${PREFIX}-media-s3" \
  --policy-document "$(sed "s#__MEDIA_BUCKET__#${MEDIA_BUCKET}#g" "${POLICY_DIR}/media-s3-policy.template.json")"
aws iam attach-role-policy \
  --role-name "${EC2_ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
aws iam create-instance-profile --instance-profile-name "${EC2_ROLE_NAME}" > /dev/null
aws iam add-role-to-instance-profile \
  --instance-profile-name "${EC2_ROLE_NAME}" --role-name "${EC2_ROLE_NAME}"
INSTANCE_PROFILE_ARN=$(aws iam get-instance-profile \
  --instance-profile-name "${EC2_ROLE_NAME}" \
  --query InstanceProfile.Arn --output text)
save_state EC2_ROLE_NAME "${EC2_ROLE_NAME}"
save_state INSTANCE_PROFILE_ARN "${INSTANCE_PROFILE_ARN}"
echo "    IAM の伝播を待機(15秒)"
sleep 15

# ---- 4. ElastiCache for Redis ----------------------------------------------------
echo "[4/8] ElastiCache(Redis)用 SG・サブネットグループ・クラスターを作成(無料枠なし)"
CACHE_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PREFIX}-cache-sg" \
  --description "Redis 6379 from app SG" \
  --vpc-id "${VPC_ID}" \
  --query GroupId --output text)
aws ec2 authorize-security-group-ingress \
  --group-id "${CACHE_SG_ID}" \
  --protocol tcp --port 6379 \
  --source-group "${APP_SG_ID}" > /dev/null
save_state CACHE_SG_ID "${CACHE_SG_ID}"

CACHE_SUBNET_GROUP="${PREFIX}-cache-subnet-group"
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name "${CACHE_SUBNET_GROUP}" \
  --cache-subnet-group-description "level4 redis subnet group" \
  --subnet-ids "${PRIVATE_DB_SUBNET_1A_ID}" "${PRIVATE_DB_SUBNET_1C_ID}" > /dev/null
save_state CACHE_SUBNET_GROUP "${CACHE_SUBNET_GROUP}"

CACHE_CLUSTER_ID="${PREFIX}-redis"
aws elasticache create-cache-cluster \
  --cache-cluster-id "${CACHE_CLUSTER_ID}" \
  --engine redis \
  --cache-node-type "${CACHE_NODE_TYPE}" \
  --num-cache-nodes 1 \
  --cache-subnet-group-name "${CACHE_SUBNET_GROUP}" \
  --security-group-ids "${CACHE_SG_ID}" > /dev/null
save_state CACHE_CLUSTER_ID "${CACHE_CLUSTER_ID}"
echo "    Redis クラスターが available になるまで待機(数分)"
aws elasticache wait cache-cluster-available --cache-cluster-id "${CACHE_CLUSTER_ID}"
REDIS_HOST=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "${CACHE_CLUSTER_ID}" \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
save_state REDIS_HOST "${REDIS_HOST}"

# ---- 5. AWS Backup: ボールト + プラン + セレクション --------------------------------
echo "[5/8] AWS Backup(毎日 03:00 JST / 30日保持)を設定"
BACKUP_VAULT="${PREFIX}-backup-vault"
aws backup create-backup-vault --backup-vault-name "${BACKUP_VAULT}" > /dev/null
save_state BACKUP_VAULT "${BACKUP_VAULT}"

BACKUP_ROLE_NAME="${PREFIX}-backup-role"
aws iam create-role \
  --role-name "${BACKUP_ROLE_NAME}" \
  --assume-role-policy-document "file://${POLICY_DIR}/backup-trust-policy.json" > /dev/null
aws iam attach-role-policy --role-name "${BACKUP_ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
aws iam attach-role-policy --role-name "${BACKUP_ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
BACKUP_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${BACKUP_ROLE_NAME}"
save_state BACKUP_ROLE_NAME "${BACKUP_ROLE_NAME}"
sleep 10

BACKUP_PLAN_ID=$(aws backup create-backup-plan \
  --backup-plan "{
    \"BackupPlanName\": \"${PREFIX}-daily-3am-30days\",
    \"Rules\": [{
      \"RuleName\": \"daily-3am-30days\",
      \"TargetBackupVaultName\": \"${BACKUP_VAULT}\",
      \"ScheduleExpression\": \"cron(0 18 * * ? *)\",
      \"StartWindowMinutes\": 60,
      \"CompletionWindowMinutes\": 180,
      \"Lifecycle\": {\"DeleteAfterDays\": 30}
    }]
  }" \
  --query BackupPlanId --output text)
save_state BACKUP_PLAN_ID "${BACKUP_PLAN_ID}"

RDS_ARN="arn:aws:rds:${AWS_DEFAULT_REGION}:${ACCOUNT_ID}:db:${RDS_INSTANCE_ID}"
BACKUP_SELECTION_ID=$(aws backup create-backup-selection \
  --backup-plan-id "${BACKUP_PLAN_ID}" \
  --backup-selection "{
    \"SelectionName\": \"${PREFIX}-rds\",
    \"IamRoleArn\": \"${BACKUP_ROLE_ARN}\",
    \"Resources\": [\"${RDS_ARN}\"]
  }" \
  --query SelectionId --output text)
save_state BACKUP_SELECTION_ID "${BACKUP_SELECTION_ID}"

# ---- 6. SNS + CloudWatch Alarm -----------------------------------------------------
echo "[6/8] SNS トピックと CloudWatch アラームを作成"
SNS_TOPIC_ARN=$(aws sns create-topic --name "${PREFIX}-alerts" --query TopicArn --output text)
aws sns subscribe --topic-arn "${SNS_TOPIC_ARN}" --protocol email --notification-endpoint "${ALERT_EMAIL}" > /dev/null
save_state SNS_TOPIC_ARN "${SNS_TOPIC_ARN}"
echo "    ${ALERT_EMAIL} に届く確認メールの「Confirm subscription」を押してください"

ALB_METRIC_DIM="${ALB_ARN#*:loadbalancer/}"

aws cloudwatch put-metric-alarm \
  --alarm-name "${PREFIX}-asg-high-cpu" \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions "Name=AutoScalingGroupName,Value=${ASG_NAME}" \
  --statistic Average --period 300 --evaluation-periods 2 \
  --threshold 80 --comparison-operator GreaterThanThreshold \
  --alarm-actions "${SNS_TOPIC_ARN}"

aws cloudwatch put-metric-alarm \
  --alarm-name "${PREFIX}-rds-low-storage" \
  --namespace AWS/RDS --metric-name FreeStorageSpace \
  --dimensions "Name=DBInstanceIdentifier,Value=${RDS_INSTANCE_ID}" \
  --statistic Average --period 300 --evaluation-periods 1 \
  --threshold 2147483648 --comparison-operator LessThanThreshold \
  --alarm-actions "${SNS_TOPIC_ARN}"

aws cloudwatch put-metric-alarm \
  --alarm-name "${PREFIX}-alb-5xx" \
  --namespace AWS/ApplicationELB --metric-name HTTPCode_ELB_5XX_Count \
  --dimensions "Name=LoadBalancer,Value=${ALB_METRIC_DIM}" \
  --statistic Sum --period 300 --evaluation-periods 1 \
  --threshold 10 --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions "${SNS_TOPIC_ARN}"
save_state ALARM_NAMES "${PREFIX}-asg-high-cpu ${PREFIX}-rds-low-storage ${PREFIX}-alb-5xx"

# ---- 7. 起動テンプレート新バージョン ------------------------------------------------
echo "[7/8] 起動テンプレートに WordPress 用バージョンを追加"
PREV_LT_VERSION=$(aws ec2 describe-launch-templates \
  --launch-template-ids "${LAUNCH_TEMPLATE_ID}" \
  --query 'LaunchTemplates[0].DefaultVersionNumber' --output text)
save_state PREV_LT_VERSION "${PREV_LT_VERSION}"

RENDERED_UD="${SCRIPT_DIR}/.rendered-user-data.sh"
sed -e "s#__REGION__#${AWS_DEFAULT_REGION}#g" \
    -e "s#__SECRET_ID__#${SECRET_NAME}#g" \
    -e "s#__REDIS_HOST__#${REDIS_HOST}#g" \
    -e "s#__MEDIA_BUCKET__#${MEDIA_BUCKET}#g" \
    "${SCRIPT_DIR}/user-data-wordpress.sh" > "${RENDERED_UD}"
USER_DATA_B64=$(base64 -w 0 "${RENDERED_UD}")

NEW_LT_VERSION=$(aws ec2 create-launch-template-version \
  --launch-template-id "${LAUNCH_TEMPLATE_ID}" \
  --source-version "${PREV_LT_VERSION}" \
  --version-description "level4 wordpress" \
  --launch-template-data "{\"UserData\":\"${USER_DATA_B64}\",\"IamInstanceProfile\":{\"Arn\":\"${INSTANCE_PROFILE_ARN}\"}}" \
  --query 'LaunchTemplateVersion.VersionNumber' --output text)
aws ec2 modify-launch-template \
  --launch-template-id "${LAUNCH_TEMPLATE_ID}" \
  --default-version "${NEW_LT_VERSION}" > /dev/null
save_state NEW_LT_VERSION "${NEW_LT_VERSION}"

# ---- 8. ASG に反映してインスタンスリフレッシュ ----------------------------------------
echo "[8/8] ASG を新バージョンに切り替えてインスタンスリフレッシュを開始"
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "${ASG_NAME}" \
  --launch-template "LaunchTemplateId=${LAUNCH_TEMPLATE_ID},Version=${NEW_LT_VERSION}"
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "${ASG_NAME}" \
  --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":300}' > /dev/null

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "${ALB_ARN}" \
  --query 'LoadBalancers[0].DNSName' --output text)

cat <<EOF

== 構築完了 ==
state ファイル : ${STATE_FILE}
ALB URL        : http://${ALB_DNS}/
Redis          : ${REDIS_HOST}:6379
メディアバケット : ${MEDIA_BUCKET}
シークレット    : ${SECRET_ARN}

インスタンスリフレッシュ完了(5〜10分)後、ALB URL を開くと WordPress の初期設定画面が表示されます。
進捗: aws autoscaling describe-instance-refreshes --auto-scaling-group-name ${ASG_NAME}
検証が終わったら必ず ./cleanup.sh を実行してください(ElastiCache は無料枠がありません)。
EOF
