#!/usr/bin/env bash
# =============================================================================
# レベル5 ハンズオン: セキュリティ監視・ガバナンス基盤を AWS CLI で構築する
#
#   フェーズ1: IAM グループ (Administrators/Developers/ReadOnly) + MFA 強制ポリシー
#   フェーズ2: CloudTrail (全リージョン証跡 + ログファイル検証)
#   フェーズ3: AWS Config (レコーダー + 配信チャネル + マネージドルール)
#   フェーズ4: GuardDuty + EventBridge + SNS メール通知
#   フェーズ5: AWS WAF (ALB_ARN が指定された場合のみ)
#
# 作成したリソースの ID は .handson-state.env に保存し、cleanup.sh が参照します。
# 注意: このスクリプトは実 AWS 環境では未検証です。実行前に内容を必ず確認してください。
# =============================================================================
set -euo pipefail

# --- 変数 --------------------------------------------------------------------
# 環境変数で上書きできます (例: REGION=us-east-1 ALERT_EMAIL=you@example.com ./build.sh)
REGION="${REGION:-ap-northeast-1}"
ALERT_EMAIL="${ALERT_EMAIL:?ALERT_EMAIL (通知先メールアドレス) を指定してください}"
ALB_ARN="${ALB_ARN:-}"          # レベル3で構築した ALB の ARN。空なら WAF フェーズはスキップ
NAME_PREFIX="${NAME_PREFIX:-sec}"

# アカウント ID は認証情報から自動取得します
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DIR="${SCRIPT_DIR}/policies"
STATE_FILE="${SCRIPT_DIR}/.handson-state.env"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# ドキュメント (../README.md) と揃えた名前
GROUP_ADMIN="Administrators"
GROUP_DEV="Developers"
GROUP_RO="ReadOnly"
MFA_POLICY_NAME="ForceMFA"
TRAIL_NAME="org-management-trail"
TRAIL_BUCKET="cloudtrail-logs-${ACCOUNT_ID}"
CONFIG_BUCKET="config-bucket-${ACCOUNT_ID}"
CONFIG_ROLE_NAME="${NAME_PREFIX}-config-role"
CONFIG_RECORDER_NAME="default"
CONFIG_CHANNEL_NAME="default"
SNS_TOPIC_NAME="security-alerts"
EVENT_RULE_NAME="${NAME_PREFIX}-guardduty-findings"
WEB_ACL_NAME="alb-protection"

export AWS_DEFAULT_REGION="${REGION}"

echo "==> アカウント: ${ACCOUNT_ID} / リージョン: ${REGION} / 通知先: ${ALERT_EMAIL}"

# 状態ファイルを初期化 (cleanup.sh が読み込みます)
cat > "${STATE_FILE}" <<EOF
REGION=${REGION}
ACCOUNT_ID=${ACCOUNT_ID}
NAME_PREFIX=${NAME_PREFIX}
GROUP_ADMIN=${GROUP_ADMIN}
GROUP_DEV=${GROUP_DEV}
GROUP_RO=${GROUP_RO}
MFA_POLICY_NAME=${MFA_POLICY_NAME}
TRAIL_NAME=${TRAIL_NAME}
TRAIL_BUCKET=${TRAIL_BUCKET}
CONFIG_BUCKET=${CONFIG_BUCKET}
CONFIG_ROLE_NAME=${CONFIG_ROLE_NAME}
CONFIG_RECORDER_NAME=${CONFIG_RECORDER_NAME}
CONFIG_CHANNEL_NAME=${CONFIG_CHANNEL_NAME}
SNS_TOPIC_NAME=${SNS_TOPIC_NAME}
EVENT_RULE_NAME=${EVENT_RULE_NAME}
WEB_ACL_NAME=${WEB_ACL_NAME}
EOF
save_state() { echo "$1=$2" >> "${STATE_FILE}"; }

# S3 バケット作成 (us-east-1 だけは LocationConstraint を付けられない仕様)
create_bucket() {
  local bucket="$1"
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${bucket}"
  else
    aws s3api create-bucket --bucket "${bucket}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  # ログ保存バケットはパブリックアクセスを完全に遮断しておきます
  aws s3api put-public-access-block --bucket "${bucket}" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
}

# =============================================================================
# フェーズ1: IAM グループと MFA 強制ポリシー
# =============================================================================
echo "==> [1/5] IAM グループを作成します"
# ⚠️ IAM の変更はアカウント全体に影響します。管理者権限で慎重に実行してください。
aws iam create-group --group-name "${GROUP_ADMIN}"
aws iam create-group --group-name "${GROUP_DEV}"
aws iam create-group --group-name "${GROUP_RO}"

# AWS 管理ポリシーをグループに付与 (ドキュメントでは Developers はカスタムポリシー推奨。
# ここでは学習用に PowerUserAccess (IAM 以外の全操作) を使い、IAM 変更権限は含めません)
aws iam attach-group-policy --group-name "${GROUP_ADMIN}" \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
aws iam attach-group-policy --group-name "${GROUP_DEV}" \
  --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess"
aws iam attach-group-policy --group-name "${GROUP_RO}" \
  --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"

# MFA 未認証セッションからの操作を Deny するカスタムポリシー (MFA デバイス登録系は許可)
MFA_POLICY_ARN="$(aws iam create-policy \
  --policy-name "${MFA_POLICY_NAME}" \
  --policy-document "file://${POLICY_DIR}/require-mfa-policy.json" \
  --query Policy.Arn --output text)"
save_state MFA_POLICY_ARN "${MFA_POLICY_ARN}"

# 人数が増えやすい Developers / ReadOnly に付与します
aws iam attach-group-policy --group-name "${GROUP_DEV}" --policy-arn "${MFA_POLICY_ARN}"
aws iam attach-group-policy --group-name "${GROUP_RO}" --policy-arn "${MFA_POLICY_ARN}"
echo "    IAM グループ 3 つと ${MFA_POLICY_NAME} ポリシーを作成しました"

# =============================================================================
# フェーズ2: CloudTrail
# =============================================================================
echo "==> [2/5] CloudTrail 証跡を作成します"
create_bucket "${TRAIL_BUCKET}"

# バケットポリシーのプレースホルダを sed で埋めて適用
sed -e "s/__BUCKET_NAME__/${TRAIL_BUCKET}/g" \
    -e "s/__ACCOUNT_ID__/${ACCOUNT_ID}/g" \
    -e "s/__REGION__/${REGION}/g" \
    -e "s/__TRAIL_NAME__/${TRAIL_NAME}/g" \
    "${POLICY_DIR}/cloudtrail-bucket-policy.template.json" > "${WORK_DIR}/trail-bucket-policy.json"
aws s3api put-bucket-policy --bucket "${TRAIL_BUCKET}" \
  --policy "file://${WORK_DIR}/trail-bucket-policy.json"

# 全リージョン対象 + ログファイル検証 (改ざん検知) を有効化した証跡
aws cloudtrail create-trail \
  --name "${TRAIL_NAME}" \
  --s3-bucket-name "${TRAIL_BUCKET}" \
  --is-multi-region-trail \
  --include-global-service-events \
  --enable-log-file-validation
aws cloudtrail start-logging --name "${TRAIL_NAME}"
echo "    証跡 ${TRAIL_NAME} のロギングを開始しました"

# =============================================================================
# フェーズ3: AWS Config
# =============================================================================
echo "==> [3/5] AWS Config を有効化します"
create_bucket "${CONFIG_BUCKET}"
sed -e "s/__BUCKET_NAME__/${CONFIG_BUCKET}/g" \
    -e "s/__ACCOUNT_ID__/${ACCOUNT_ID}/g" \
    "${POLICY_DIR}/config-bucket-policy.template.json" > "${WORK_DIR}/config-bucket-policy.json"
aws s3api put-bucket-policy --bucket "${CONFIG_BUCKET}" \
  --policy "file://${WORK_DIR}/config-bucket-policy.json"

# Config が各リソースを読み取り S3 へ配信するためのサービスロール
CONFIG_ROLE_ARN="$(aws iam create-role \
  --role-name "${CONFIG_ROLE_NAME}" \
  --assume-role-policy-document "file://${POLICY_DIR}/config-trust-policy.json" \
  --query Role.Arn --output text)"
aws iam attach-role-policy --role-name "${CONFIG_ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
save_state CONFIG_ROLE_ARN "${CONFIG_ROLE_ARN}"

# IAM ロールが各サービスへ伝播するまで少し待ちます
echo "    IAM ロールの伝播を待機中 (15秒)..."
sleep 15

# レコーダー: サポート対象の全リソース + グローバルリソース (IAM など) を記録
aws configservice put-configuration-recorder \
  --configuration-recorder "name=${CONFIG_RECORDER_NAME},roleARN=${CONFIG_ROLE_ARN}" \
  --recording-group "allSupported=true,includeGlobalResourceTypes=true"
aws configservice put-delivery-channel \
  --delivery-channel "name=${CONFIG_CHANNEL_NAME},s3BucketName=${CONFIG_BUCKET}"
aws configservice start-configuration-recorder \
  --configuration-recorder-name "${CONFIG_RECORDER_NAME}"

# マネージドルール (ドキュメントの 2 つ + ルート MFA チェック)
aws configservice put-config-rule --config-rule \
  '{"ConfigRuleName":"s3-bucket-public-read-prohibited","Source":{"Owner":"AWS","SourceIdentifier":"S3_BUCKET_PUBLIC_READ_PROHIBITED"}}'
aws configservice put-config-rule --config-rule \
  '{"ConfigRuleName":"restricted-ssh","Source":{"Owner":"AWS","SourceIdentifier":"INCOMING_SSH_DISABLED"}}'
aws configservice put-config-rule --config-rule \
  '{"ConfigRuleName":"root-account-mfa-enabled","Source":{"Owner":"AWS","SourceIdentifier":"ROOT_ACCOUNT_MFA_ENABLED"}}'
save_state CONFIG_RULES "s3-bucket-public-read-prohibited restricted-ssh root-account-mfa-enabled"
echo "    Config レコーダーとマネージドルール 3 つを設定しました"

# =============================================================================
# フェーズ4: GuardDuty + SNS + EventBridge
# =============================================================================
echo "==> [4/5] GuardDuty と通知経路を構築します"
# 💰 GuardDuty は有効化している間ずっと課金されます (初回 30 日間はトライアル)
DETECTOR_ID="$(aws guardduty create-detector --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --query DetectorId --output text)"
save_state DETECTOR_ID "${DETECTOR_ID}"

# SNS トピック + メール購読 (届いた確認メールのリンクを必ずクリックしてください)
SNS_TOPIC_ARN="$(aws sns create-topic --name "${SNS_TOPIC_NAME}" \
  --query TopicArn --output text)"
save_state SNS_TOPIC_ARN "${SNS_TOPIC_ARN}"
aws sns subscribe --topic-arn "${SNS_TOPIC_ARN}" \
  --protocol email --notification-endpoint "${ALERT_EMAIL}"

# EventBridge からトピックへ Publish できるようトピックポリシーを設定
sed -e "s/__ACCOUNT_ID__/${ACCOUNT_ID}/g" \
    -e "s#__TOPIC_ARN__#${SNS_TOPIC_ARN}#g" \
    "${POLICY_DIR}/sns-topic-policy.template.json" > "${WORK_DIR}/sns-topic-policy.json"
aws sns set-topic-attributes --topic-arn "${SNS_TOPIC_ARN}" \
  --attribute-name Policy \
  --attribute-value "file://${WORK_DIR}/sns-topic-policy.json"

# GuardDuty Finding (severity 4 以上) を拾う EventBridge ルール → SNS ターゲット
aws events put-rule --name "${EVENT_RULE_NAME}" \
  --event-pattern "file://${POLICY_DIR}/guardduty-eventbridge-pattern.json" \
  --state ENABLED
aws events put-targets --rule "${EVENT_RULE_NAME}" \
  --targets "Id=sns-security-alerts,Arn=${SNS_TOPIC_ARN}"
echo "    GuardDuty (${DETECTOR_ID}) → EventBridge → SNS の通知経路を作成しました"

# =============================================================================
# フェーズ5: AWS WAF (ALB_ARN 指定時のみ)
# =============================================================================
if [ -n "${ALB_ARN}" ]; then
  echo "==> [5/5] AWS WAF を作成し ALB に関連付けます"
  # 💰 Web ACL は作成している間ずっと月額固定費が発生します
  # AWSManagedRulesCommonRuleSet (SQLi/XSS などの代表的な攻撃パターン) を有効化
  cat > "${WORK_DIR}/waf-rules.json" <<'EOF'
[
  {
    "Name": "AWSManagedRulesCommonRuleSet",
    "Priority": 0,
    "Statement": {
      "ManagedRuleGroupStatement": {
        "VendorName": "AWS",
        "Name": "AWSManagedRulesCommonRuleSet"
      }
    },
    "OverrideAction": { "None": {} },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "AWSManagedRulesCommonRuleSet"
    }
  }
]
EOF
  WEB_ACL_ARN="$(aws wafv2 create-web-acl \
    --name "${WEB_ACL_NAME}" \
    --scope REGIONAL \
    --default-action Allow={} \
    --rules "file://${WORK_DIR}/waf-rules.json" \
    --visibility-config "SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=${WEB_ACL_NAME}" \
    --query Summary.ARN --output text)"
  WEB_ACL_ID="${WEB_ACL_ARN##*/}"
  save_state WEB_ACL_ARN "${WEB_ACL_ARN}"
  save_state WEB_ACL_ID "${WEB_ACL_ID}"
  save_state ALB_ARN "${ALB_ARN}"

  aws wafv2 associate-web-acl --web-acl-arn "${WEB_ACL_ARN}" --resource-arn "${ALB_ARN}"
  echo "    Web ACL ${WEB_ACL_NAME} を ALB に関連付けました"
else
  echo "==> [5/5] ALB_ARN が未指定のため WAF フェーズはスキップします"
fi

# =============================================================================
echo ""
echo "==> 構築が完了しました。状態は ${STATE_FILE} に保存されています"
echo "    1. ${ALERT_EMAIL} に届いた SNS の確認メールを承認してください"
echo "    2. 証跡の状態確認: aws cloudtrail get-trail-status --name ${TRAIL_NAME} --query IsLogging"
echo "    3. Config 評価確認: aws configservice describe-compliance-by-config-rule --config-rule-names restricted-ssh"
echo "    4. 検証が終わったら ./cleanup.sh で削除してください (GuardDuty/Config/WAF は常時課金)"
