#!/usr/bin/env bash
# =============================================================================
# cleanup.sh
# build.sh が作成したリソースを、作成時と逆の順番で削除します。
#   Elastic IP 解放 → EC2 終了 → SG → ルートテーブル → IGW → サブネット → VPC → キーペア
# .handson-state.env に記録されたIDを読み込んで動作します。
# 一部の削除に失敗しても続行できるよう、各手順は個別にエラーを握りつぶしています。
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${SCRIPT_DIR}/.handson-state.env"

if [[ ! -f "${STATE_FILE}" ]]; then
  echo "エラー: ${STATE_FILE} が見つかりません。build.sh で作成したリソースがないか、既に削除済みです。" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${STATE_FILE}"
REGION="${REGION:-ap-northeast-1}"

echo "=== 削除を開始します (リージョン: ${REGION}) ==="

# --- 1. Elastic IP の関連付け解除と解放(未アタッチのまま残すと課金されます) ---
if [[ -n "${ALLOC_ID:-}" ]]; then
  echo "[1/8] Elastic IP を解放中... (${ALLOC_ID})"
  ASSOC_ID="$(aws ec2 describe-addresses --region "${REGION}" --allocation-ids "${ALLOC_ID}" \
    --query 'Addresses[0].AssociationId' --output text 2>/dev/null || true)"
  if [[ -n "${ASSOC_ID}" && "${ASSOC_ID}" != "None" ]]; then
    aws ec2 disassociate-address --region "${REGION}" --association-id "${ASSOC_ID}" || true
  fi
  aws ec2 release-address --region "${REGION}" --allocation-id "${ALLOC_ID}" || true
fi

# --- 2. EC2 インスタンスの終了(完全に terminated になるまで待機) ---
if [[ -n "${INSTANCE_ID:-}" ]]; then
  echo "[2/8] EC2 インスタンスを終了中... (${INSTANCE_ID})"
  aws ec2 terminate-instances --region "${REGION}" --instance-ids "${INSTANCE_ID}" > /dev/null || true
  echo "  terminated になるまで待機します(1〜2分)..."
  aws ec2 wait instance-terminated --region "${REGION}" --instance-ids "${INSTANCE_ID}" || true
fi

# --- 3. セキュリティグループの削除(インスタンス終了後でないと削除できません) ---
if [[ -n "${SG_ID:-}" ]]; then
  echo "[3/8] セキュリティグループを削除中... (${SG_ID})"
  aws ec2 delete-security-group --region "${REGION}" --group-id "${SG_ID}" || true
fi

# --- 4. ルートテーブルの関連付け解除と削除 ---
if [[ -n "${RTB_ASSOC_ID:-}" ]]; then
  echo "[4/8] ルートテーブルの関連付けを解除中... (${RTB_ASSOC_ID})"
  aws ec2 disassociate-route-table --region "${REGION}" --association-id "${RTB_ASSOC_ID}" || true
fi
if [[ -n "${RTB_ID:-}" ]]; then
  echo "      ルートテーブルを削除中... (${RTB_ID})"
  aws ec2 delete-route-table --region "${REGION}" --route-table-id "${RTB_ID}" || true
fi

# --- 5. インターネットゲートウェイのデタッチと削除 ---
if [[ -n "${IGW_ID:-}" && -n "${VPC_ID:-}" ]]; then
  echo "[5/8] インターネットゲートウェイをデタッチ・削除中... (${IGW_ID})"
  aws ec2 detach-internet-gateway --region "${REGION}" --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}" || true
  aws ec2 delete-internet-gateway --region "${REGION}" --internet-gateway-id "${IGW_ID}" || true
fi

# --- 6. サブネットの削除 ---
if [[ -n "${SUBNET_ID:-}" ]]; then
  echo "[6/8] サブネットを削除中... (${SUBNET_ID})"
  aws ec2 delete-subnet --region "${REGION}" --subnet-id "${SUBNET_ID}" || true
fi

# --- 7. VPC の削除(中身がすべて消えていないと失敗します) ---
if [[ -n "${VPC_ID:-}" ]]; then
  echo "[7/8] VPC を削除中... (${VPC_ID})"
  aws ec2 delete-vpc --region "${REGION}" --vpc-id "${VPC_ID}" || true
fi

# --- 8. キーペアの削除(AWS側の公開鍵)と手元の .pem の削除 ---
if [[ -n "${KEY_NAME:-}" ]]; then
  echo "[8/8] キーペアを削除中... (${KEY_NAME})"
  aws ec2 delete-key-pair --region "${REGION}" --key-name "${KEY_NAME}" || true
fi
if [[ -n "${PEM_FILE:-}" && -f "${PEM_FILE}" ]]; then
  rm -f "${PEM_FILE}"
  echo "  秘密鍵ファイルを削除しました: ${PEM_FILE}"
fi

# --- 状態ファイルを削除 ---
rm -f "${STATE_FILE}"

cat <<EOF

=== 削除が完了しました ===
  念のためマネジメントコンソールで、以下が残っていないか確認してください。
    - EC2 > Elastic IP(未アタッチのEIPは課金対象です)
    - EC2 > インスタンス(terminated 以外のものがないこと)
    - VPC > お使いのVPC(${NAME_PREFIX:-handson}-web-vpc が消えていること)
EOF
