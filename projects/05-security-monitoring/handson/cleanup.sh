#!/usr/bin/env bash
# =============================================================================
# レベル5 ハンズオン: build.sh で作成したリソースを逆順に削除する
#
# .handson-state.env を読み込み、WAF → EventBridge → SNS → GuardDuty → Config
# → CloudTrail → S3 バケット → IAM の順で削除します。
# 途中で失敗しても続行できるよう、各コマンドは "|| true" で失敗を許容しています。
# 注意: このスクリプトは実 AWS 環境では未検証です。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${SCRIPT_DIR}/.handson-state.env"

if [ ! -f "${STATE_FILE}" ]; then
  echo "状態ファイル ${STATE_FILE} が見つかりません。build.sh を実行した環境で実行してください" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${STATE_FILE}"
export AWS_DEFAULT_REGION="${REGION}"

echo "==> アカウント: ${ACCOUNT_ID} / リージョン: ${REGION} のリソースを削除します"

# =============================================================================
# フェーズ5: WAF (作成していた場合のみ)
# =============================================================================
if [ -n "${WEB_ACL_ARN:-}" ]; then
  echo "==> [1/6] WAF の関連付けを解除して Web ACL を削除します"
  aws wafv2 disassociate-web-acl --resource-arn "${ALB_ARN}" || true
  # 削除には最新の LockToken が必要なので取得してから削除します
  LOCK_TOKEN="$(aws wafv2 get-web-acl --name "${WEB_ACL_NAME}" --scope REGIONAL \
    --id "${WEB_ACL_ID}" --query LockToken --output text || true)"
  if [ -n "${LOCK_TOKEN}" ] && [ "${LOCK_TOKEN}" != "None" ]; then
    aws wafv2 delete-web-acl --name "${WEB_ACL_NAME}" --scope REGIONAL \
      --id "${WEB_ACL_ID}" --lock-token "${LOCK_TOKEN}" || true
  fi
else
  echo "==> [1/6] WAF は作成されていないためスキップします"
fi

# =============================================================================
# フェーズ4: EventBridge → SNS → GuardDuty
# =============================================================================
echo "==> [2/6] EventBridge ルールと SNS トピックを削除します"
# ターゲットを外してからでないとルールは削除できません
aws events remove-targets --rule "${EVENT_RULE_NAME}" --ids sns-security-alerts || true
aws events delete-rule --name "${EVENT_RULE_NAME}" || true
# トピック削除で購読 (確認済み分) も一緒に消えます
if [ -n "${SNS_TOPIC_ARN:-}" ]; then
  aws sns delete-topic --topic-arn "${SNS_TOPIC_ARN}" || true
fi

echo "==> [3/6] GuardDuty ディテクターを削除します"
if [ -n "${DETECTOR_ID:-}" ]; then
  aws guardduty delete-detector --detector-id "${DETECTOR_ID}" || true
fi

# =============================================================================
# フェーズ3: AWS Config
# =============================================================================
echo "==> [4/6] AWS Config のルール・レコーダー・配信チャネルを削除します"
for rule in ${CONFIG_RULES:-}; do
  aws configservice delete-config-rule --config-rule-name "${rule}" || true
done
aws configservice stop-configuration-recorder \
  --configuration-recorder-name "${CONFIG_RECORDER_NAME}" || true
aws configservice delete-delivery-channel \
  --delivery-channel-name "${CONFIG_CHANNEL_NAME}" || true
aws configservice delete-configuration-recorder \
  --configuration-recorder-name "${CONFIG_RECORDER_NAME}" || true
aws iam detach-role-policy --role-name "${CONFIG_ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole" || true
aws iam delete-role --role-name "${CONFIG_ROLE_NAME}" || true

# =============================================================================
# フェーズ2: CloudTrail と S3 バケット
# =============================================================================
echo "==> [5/6] CloudTrail 証跡とログ用 S3 バケットを削除します"
aws cloudtrail stop-logging --name "${TRAIL_NAME}" || true
aws cloudtrail delete-trail --name "${TRAIL_NAME}" || true

# バケットは中身を空にしないと削除できません
for bucket in "${TRAIL_BUCKET}" "${CONFIG_BUCKET}"; do
  echo "    バケット ${bucket} を空にして削除します"
  aws s3 rm "s3://${bucket}" --recursive || true
  aws s3api delete-bucket --bucket "${bucket}" || true
done

# =============================================================================
# フェーズ1: IAM グループとポリシー
# =============================================================================
echo "==> [6/6] IAM グループとポリシーを削除します"
# ⚠️ グループにユーザーを追加していた場合は先に remove-user-from-group してください
aws iam detach-group-policy --group-name "${GROUP_ADMIN}" \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" || true
aws iam detach-group-policy --group-name "${GROUP_DEV}" \
  --policy-arn "arn:aws:iam::aws:policy/PowerUserAccess" || true
aws iam detach-group-policy --group-name "${GROUP_RO}" \
  --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" || true
if [ -n "${MFA_POLICY_ARN:-}" ]; then
  aws iam detach-group-policy --group-name "${GROUP_DEV}" --policy-arn "${MFA_POLICY_ARN}" || true
  aws iam detach-group-policy --group-name "${GROUP_RO}" --policy-arn "${MFA_POLICY_ARN}" || true
  aws iam delete-policy --policy-arn "${MFA_POLICY_ARN}" || true
fi
aws iam delete-group --group-name "${GROUP_ADMIN}" || true
aws iam delete-group --group-name "${GROUP_DEV}" || true
aws iam delete-group --group-name "${GROUP_RO}" || true

rm -f "${STATE_FILE}"
echo ""
echo "==> 削除が完了しました。コンソールで GuardDuty / Config / WAF が残っていないか最終確認してください"
