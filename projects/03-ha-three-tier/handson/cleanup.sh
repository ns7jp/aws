#!/usr/bin/env bash
# =============================================================================
# レベル3: 可用性を高めた3層Webシステム 削除スクリプト
#   build.sh が .handson-state.env に保存したリソースIDを読み込み、依存関係の逆順で削除します。
#   一部のリソースが既に消えていても続行できるよう、各削除は失敗しても止まらないようにしています。
# =============================================================================
set -euo pipefail

STATE_FILE="$(cd "$(dirname "$0")" && pwd)/.handson-state.env"
if [[ ! -f "$STATE_FILE" ]]; then
  echo "エラー: $STATE_FILE が見つかりません。build.sh で作成した環境がありません。"
  exit 1
fi
# shellcheck disable=SC1090
source "$STATE_FILE"
export AWS_DEFAULT_REGION="${REGION:-ap-northeast-1}"

echo "=== 削除を開始します(状態ファイル: $STATE_FILE) ==="

# --- 1. RDS(最も時間がかかるので最初に開始) ---
if [[ -n "${DB_IDENTIFIER:-}" ]]; then
  echo "[1/13] RDS $DB_IDENTIFIER を削除します(最終スナップショットなし)..."
  aws rds delete-db-instance \
    --db-instance-identifier "$DB_IDENTIFIER" \
    --skip-final-snapshot \
    --delete-automated-backups > /dev/null || true
  aws rds wait db-instance-deleted --db-instance-identifier "$DB_IDENTIFIER" || true
fi

# --- 2. DBサブネットグループ ---
if [[ -n "${DB_SUBNET_GROUP:-}" ]]; then
  echo "[2/13] DBサブネットグループ $DB_SUBNET_GROUP を削除します..."
  aws rds delete-db-subnet-group --db-subnet-group-name "$DB_SUBNET_GROUP" || true
fi

# --- 3. Auto Scaling Group(台数を 0 にしてから強制削除し、インスタンス終了を待つ) ---
if [[ -n "${ASG_NAME:-}" ]]; then
  echo "[3/13] ASG $ASG_NAME を縮退・削除します..."
  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" --min-size 0 --desired-capacity 0 || true
  aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" --force-delete || true
  # ASG が完全に消えるまでポーリング(インスタンス終了完了を待つ)
  for _ in $(seq 1 60); do
    COUNT=$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$ASG_NAME" \
      --query 'length(AutoScalingGroups)' --output text 2>/dev/null || echo 0)
    [[ "$COUNT" == "0" ]] && break
    sleep 10
  done
fi

# --- 4. ALB(リスナーは ALB と一緒に消えます) ---
if [[ -n "${ALB_ARN:-}" ]]; then
  echo "[4/13] ALB を削除します..."
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" || true
  aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN" || true
fi

# --- 5. ターゲットグループ ---
if [[ -n "${TG_ARN:-}" ]]; then
  echo "[5/13] ターゲットグループを削除します..."
  aws elbv2 delete-target-group --target-group-arn "$TG_ARN" || true
fi

# --- 6. 起動テンプレート ---
if [[ -n "${LT_ID:-}" ]]; then
  echo "[6/13] 起動テンプレート $LT_ID を削除します..."
  aws ec2 delete-launch-template --launch-template-id "$LT_ID" > /dev/null || true
fi

# --- 7. NATゲートウェイ(削除完了まで待機。ENI が残ると VPC を消せないため) ---
if [[ -n "${NAT_GW_ID:-}" ]]; then
  echo "[7/13] NATゲートウェイ $NAT_GW_ID を削除します(数分かかります)..."
  aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GW_ID" > /dev/null || true
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_GW_ID" || true
fi

# --- 8. Elastic IP の解放(解放し忘れると課金対象になります) ---
if [[ -n "${EIP_ALLOC_ID:-}" ]]; then
  echo "[8/13] Elastic IP $EIP_ALLOC_ID を解放します..."
  aws ec2 release-address --allocation-id "$EIP_ALLOC_ID" || true
fi

# --- 9. セキュリティグループ(依存順: db → app → alb) ---
#     ALB/EC2 の ENI が消えるまで時間差があるため、数回リトライします
delete_sg() {
  local sg_id="$1"
  for _ in $(seq 1 12); do
    if aws ec2 delete-security-group --group-id "$sg_id" 2>/dev/null; then
      return 0
    fi
    sleep 10
  done
  echo "  警告: SG $sg_id を削除できませんでした。手動で確認してください。"
  return 0
}
echo "[9/13] セキュリティグループを削除します..."
[[ -n "${DB_SG_ID:-}" ]]  && delete_sg "$DB_SG_ID"
[[ -n "${APP_SG_ID:-}" ]] && delete_sg "$APP_SG_ID"
[[ -n "${ALB_SG_ID:-}" ]] && delete_sg "$ALB_SG_ID"

# --- 10. ルートテーブル(関連付けを外してから削除) ---
delete_rt() {
  local rt_id="$1"
  # 明示的な関連付けをすべて解除
  for assoc in $(aws ec2 describe-route-tables --route-table-ids "$rt_id" \
      --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' \
      --output text 2>/dev/null); do
    aws ec2 disassociate-route-table --association-id "$assoc" || true
  done
  aws ec2 delete-route-table --route-table-id "$rt_id" || true
}
echo "[10/13] ルートテーブルを削除します..."
[[ -n "${PRIVATE_APP_RT_ID:-}" ]] && delete_rt "$PRIVATE_APP_RT_ID"
[[ -n "${PUBLIC_RT_ID:-}" ]]      && delete_rt "$PUBLIC_RT_ID"

# --- 11. インターネットゲートウェイ(デタッチしてから削除) ---
if [[ -n "${IGW_ID:-}" ]]; then
  echo "[11/13] IGW $IGW_ID を削除します..."
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" || true
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" || true
fi

# --- 12. サブネット ---
echo "[12/13] サブネットを削除します..."
for subnet in "${SUBNET_PUBLIC_A:-}" "${SUBNET_PUBLIC_C:-}" "${SUBNET_APP_A:-}" \
              "${SUBNET_APP_C:-}" "${SUBNET_DB_A:-}" "${SUBNET_DB_C:-}"; do
  [[ -n "$subnet" ]] && { aws ec2 delete-subnet --subnet-id "$subnet" || true; }
done

# --- 13. VPC ---
if [[ -n "${VPC_ID:-}" ]]; then
  echo "[13/13] VPC $VPC_ID を削除します..."
  aws ec2 delete-vpc --vpc-id "$VPC_ID" || true
fi

rm -f "$STATE_FILE"
echo ""
echo "=== 削除が完了しました。マネジメントコンソールで残存リソース(特に NAT/ALB/RDS/EIP)がないことを確認してください ==="
