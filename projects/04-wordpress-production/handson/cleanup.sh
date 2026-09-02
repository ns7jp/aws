#!/usr/bin/env bash
# レベル4 差分キットで追加したリソースを逆順に削除する(レベル3 のリソースは残す)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${SCRIPT_DIR}/.handson-state.env"
L3_STATE="${SCRIPT_DIR}/../../03-ha-three-tier/handson/.handson-state.env"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-northeast-1}"

for f in "${STATE_FILE}" "${L3_STATE}"; do
  if [[ ! -f "${f}" ]]; then
    echo "ERROR: state ファイルが見つかりません: ${f}" >&2
    exit 1
  fi
done
# shellcheck disable=SC1090
source "${L3_STATE}"
# shellcheck disable=SC1090
source "${STATE_FILE}"

ok() { "$@" > /dev/null 2>&1 || echo "    (skip) $*"; }

# ---- 8. ASG / 起動テンプレートをレベル3 の状態に戻す ----------------------------------
echo "[1/8] ASG を以前の起動テンプレートバージョン(${PREV_LT_VERSION:-?})に戻す"
if [[ -n "${PREV_LT_VERSION:-}" ]]; then
  ok aws autoscaling cancel-instance-refresh --auto-scaling-group-name "${ASG_NAME}"
  ok aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "${ASG_NAME}" \
    --launch-template "LaunchTemplateId=${LAUNCH_TEMPLATE_ID},Version=${PREV_LT_VERSION}"
  ok aws ec2 modify-launch-template \
    --launch-template-id "${LAUNCH_TEMPLATE_ID}" --default-version "${PREV_LT_VERSION}"
  ok aws ec2 delete-launch-template-versions \
    --launch-template-id "${LAUNCH_TEMPLATE_ID}" --versions "${NEW_LT_VERSION}"
  ok aws autoscaling start-instance-refresh \
    --auto-scaling-group-name "${ASG_NAME}" \
    --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":300}'
fi
rm -f "${SCRIPT_DIR}/.rendered-user-data.sh"

# ---- 7. CloudWatch Alarm / SNS ------------------------------------------------------
echo "[2/8] CloudWatch アラームと SNS トピックを削除"
if [[ -n "${ALARM_NAMES:-}" ]]; then
  # shellcheck disable=SC2086
  ok aws cloudwatch delete-alarms --alarm-names ${ALARM_NAMES}
fi
if [[ -n "${SNS_TOPIC_ARN:-}" ]]; then
  ok aws sns delete-topic --topic-arn "${SNS_TOPIC_ARN}"
fi

# ---- 6. AWS Backup ------------------------------------------------------------------
echo "[3/8] AWS Backup のセレクション・プラン・復旧ポイント・ボールト・ロールを削除"
if [[ -n "${BACKUP_PLAN_ID:-}" ]]; then
  ok aws backup delete-backup-selection \
    --backup-plan-id "${BACKUP_PLAN_ID}" --selection-id "${BACKUP_SELECTION_ID}"
  ok aws backup delete-backup-plan --backup-plan-id "${BACKUP_PLAN_ID}"
fi
if [[ -n "${BACKUP_VAULT:-}" ]]; then
  for rp in $(aws backup list-recovery-points-by-backup-vault \
      --backup-vault-name "${BACKUP_VAULT}" \
      --query 'RecoveryPoints[].RecoveryPointArn' --output text 2>/dev/null || true); do
    ok aws backup delete-recovery-point --backup-vault-name "${BACKUP_VAULT}" --recovery-point-arn "${rp}"
  done
  ok aws backup delete-backup-vault --backup-vault-name "${BACKUP_VAULT}"
fi
if [[ -n "${BACKUP_ROLE_NAME:-}" ]]; then
  ok aws iam detach-role-policy --role-name "${BACKUP_ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  ok aws iam detach-role-policy --role-name "${BACKUP_ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  ok aws iam delete-role --role-name "${BACKUP_ROLE_NAME}"
fi

# ---- 5. ElastiCache -----------------------------------------------------------------
echo "[4/8] ElastiCache クラスターを削除(完了まで数分待機)"
if [[ -n "${CACHE_CLUSTER_ID:-}" ]]; then
  ok aws elasticache delete-cache-cluster --cache-cluster-id "${CACHE_CLUSTER_ID}"
  ok aws elasticache wait cache-cluster-deleted --cache-cluster-id "${CACHE_CLUSTER_ID}"
fi
if [[ -n "${CACHE_SUBNET_GROUP:-}" ]]; then
  ok aws elasticache delete-cache-subnet-group --cache-subnet-group-name "${CACHE_SUBNET_GROUP}"
fi
if [[ -n "${CACHE_SG_ID:-}" ]]; then
  ok aws ec2 delete-security-group --group-id "${CACHE_SG_ID}"
fi

# ---- 4. EC2 用 IAM ------------------------------------------------------------------
echo "[5/8] EC2 用インスタンスプロファイルとロールを削除"
if [[ -n "${EC2_ROLE_NAME:-}" ]]; then
  ok aws iam remove-role-from-instance-profile \
    --instance-profile-name "${EC2_ROLE_NAME}" --role-name "${EC2_ROLE_NAME}"
  ok aws iam delete-instance-profile --instance-profile-name "${EC2_ROLE_NAME}"
  ok aws iam detach-role-policy --role-name "${EC2_ROLE_NAME}" \
    --policy-arn "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ok aws iam delete-role-policy --role-name "${EC2_ROLE_NAME}" --policy-name "${PREFIX:-wp-prod}-secrets-read"
  ok aws iam delete-role-policy --role-name "${EC2_ROLE_NAME}" --policy-name "${PREFIX:-wp-prod}-media-s3"
  ok aws iam delete-role --role-name "${EC2_ROLE_NAME}"
fi

# ---- 3. S3 --------------------------------------------------------------------------
echo "[6/8] S3 メディアバケットを空にして削除"
if [[ -n "${MEDIA_BUCKET:-}" ]]; then
  ok aws s3 rm "s3://${MEDIA_BUCKET}" --recursive
  ok aws s3api delete-bucket --bucket "${MEDIA_BUCKET}"
fi

# ---- 2. Secrets Manager -------------------------------------------------------------
echo "[7/8] シークレットを即時削除"
if [[ -n "${SECRET_ARN:-}" ]]; then
  ok aws secretsmanager delete-secret --secret-id "${SECRET_ARN}" --force-delete-without-recovery
fi

# ---- 1. state -----------------------------------------------------------------------
echo "[8/8] state ファイルを削除"
rm -f "${STATE_FILE}"

cat <<'EOF'

== レベル4 の差分リソースを削除しました ==
レベル3 のリソース(ALB / NAT / RDS Multi-AZ など)は残っています。
続けて課金を止めるには ../../03-ha-three-tier/handson/cleanup.sh を実行してください。
EOF
