#!/usr/bin/env bash
# =============================================================================
# レベル1: 静的Webサイト公開環境 後片付けスクリプト
#
# build.sh が作成したリソースを逆順に削除します。
#   1. CloudFrontディストリビューションを無効化(disable)→ 反映待ち → 削除
#   2. OAC(Origin Access Control)を削除
#   3. S3バケットを空にしてから削除
#
# build.sh が書き出した .state ファイルからリソースIDを読み込みます。
# ⚠️ このスクリプトは実AWS環境で未検証です。実行前に必ず内容を読んでください。
# ⚠️ 独自ドメインを設定した場合、ACM証明書・Route 53のレコード/ホストゾーンは
#    このスクリプトでは削除しません。コンソールから手動で削除してください。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${SCRIPT_DIR}/.state"
WORK_DIR="${SCRIPT_DIR}/.work"

if [[ ! -f "${STATE_FILE}" ]]; then
  echo "エラー: ${STATE_FILE} が見つかりません。build.sh を実行した後に使ってください。"
  echo "手動で削除する場合は、このファイルに以下の形式で記述してから再実行してください:"
  echo "  BUCKET_NAME=..."
  echo "  REGION=..."
  echo "  OAC_ID=..."
  echo "  DISTRIBUTION_ID=..."
  exit 1
fi

# .state を読み込む(KEY=VALUE 形式)
# shellcheck disable=SC1090
source "${STATE_FILE}"
BUCKET_NAME="${BUCKET_NAME:-}"
REGION="${REGION:-ap-northeast-1}"
OAC_ID="${OAC_ID:-}"
DISTRIBUTION_ID="${DISTRIBUTION_ID:-}"

echo "=============================================="
echo " 以下のリソースを削除します"
echo "   Distribution ID : ${DISTRIBUTION_ID:-(なし)}"
echo "   OAC ID          : ${OAC_ID:-(なし)}"
echo "   S3バケット       : ${BUCKET_NAME:-(なし)}"
echo "=============================================="
read -r -p "本当に削除しますか? (yes と入力): " ANSWER
if [[ "${ANSWER}" != "yes" ]]; then
  echo "中止しました"
  exit 0
fi
mkdir -p "${WORK_DIR}"

# -----------------------------------------------------------------------------
# 1. CloudFrontディストリビューションの無効化 → 待機 → 削除
#    CloudFrontは「有効なまま削除」ができないため、まず Enabled=false に更新します。
# -----------------------------------------------------------------------------
if [[ -n "${DISTRIBUTION_ID}" ]]; then
  echo ""
  echo "[1/3] ディストリビューション ${DISTRIBUTION_ID} を無効化します"
  CURRENT_CONFIG="${WORK_DIR}/current-distribution-config.json"
  aws cloudfront get-distribution-config --id "${DISTRIBUTION_ID}" --output json > "${CURRENT_CONFIG}"

  # 更新時に必要な ETag(楽観ロック用の版番号)を取り出す
  ETAG="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ETag"])' "${CURRENT_CONFIG}")"
  IS_ENABLED="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["DistributionConfig"]["Enabled"])' "${CURRENT_CONFIG}")"

  if [[ "${IS_ENABLED}" == "True" ]]; then
    # DistributionConfig 部分だけを取り出し、Enabled を false にして書き戻す
    DISABLED_CONFIG="${WORK_DIR}/disabled-distribution-config.json"
    python3 - "${CURRENT_CONFIG}" "${DISABLED_CONFIG}" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
cfg = json.load(open(src))["DistributionConfig"]
cfg["Enabled"] = False
json.dump(cfg, open(dst, "w"), ensure_ascii=False, indent=2)
PY
    aws cloudfront update-distribution \
      --id "${DISTRIBUTION_ID}" \
      --if-match "${ETAG}" \
      --distribution-config "file://${DISABLED_CONFIG}" \
      --output json > "${WORK_DIR}/update-distribution.json"
    echo "  -> 無効化を要求しました。反映を待ちます(数分〜十数分)..."
    aws cloudfront wait distribution-deployed --id "${DISTRIBUTION_ID}"
  else
    echo "  -> 既に無効化されています"
  fi

  # 削除には最新の ETag が必要なので取り直す
  ETAG="$(aws cloudfront get-distribution-config --id "${DISTRIBUTION_ID}" --query 'ETag' --output text)"
  echo "[1/3] ディストリビューションを削除します"
  aws cloudfront delete-distribution --id "${DISTRIBUTION_ID}" --if-match "${ETAG}"
  echo "  -> 削除しました"
else
  echo "[1/3] DISTRIBUTION_ID が未設定のためスキップします"
fi

# -----------------------------------------------------------------------------
# 2. OAC(Origin Access Control)の削除
#    ディストリビューションから参照されている間は削除できないため、1. の後に行います。
# -----------------------------------------------------------------------------
if [[ -n "${OAC_ID}" ]]; then
  echo ""
  echo "[2/3] OAC ${OAC_ID} を削除します"
  OAC_ETAG="$(aws cloudfront get-origin-access-control --id "${OAC_ID}" --query 'ETag' --output text)"
  aws cloudfront delete-origin-access-control --id "${OAC_ID}" --if-match "${OAC_ETAG}"
  echo "  -> 削除しました"
else
  echo "[2/3] OAC_ID が未設定のためスキップします"
fi

# -----------------------------------------------------------------------------
# 3. S3バケットを空にしてから削除
#    S3は「中身が残っているバケット」を削除できません。
# -----------------------------------------------------------------------------
if [[ -n "${BUCKET_NAME}" ]]; then
  echo ""
  echo "[3/3] S3バケット ${BUCKET_NAME} を空にして削除します"
  if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    aws s3 rm "s3://${BUCKET_NAME}" --recursive
    aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
    echo "  -> 削除しました"
  else
    echo "  -> バケットが存在しません(スキップ)"
  fi
else
  echo "[3/3] BUCKET_NAME が未設定のためスキップします"
fi

# -----------------------------------------------------------------------------
# ローカルの作業ファイルを片付ける
# -----------------------------------------------------------------------------
rm -rf "${WORK_DIR}"
rm -f "${STATE_FILE}"

echo ""
echo "=============================================="
echo " 後片付けが完了しました。"
echo " 独自ドメインを設定していた場合は、ACM証明書と Route 53 のレコード/"
echo " ホストゾーン(約0.5USD/月)をコンソールから手動で削除してください。"
echo " 最後に AWS Billing コンソールで料金が発生していないか確認しましょう。"
echo "=============================================="
