#!/usr/bin/env bash
# =============================================================================
# レベル3: 可用性を高めた3層Webシステム 構築スクリプト
#   ../README.md のハンズオン手順(フェーズ1〜8)を AWS CLI v2 で自動化したものです。
#   作成したリソースIDは .handson-state.env に保存し、cleanup.sh が削除に使います。
#
#   実行例:
#     export DB_USERNAME=admin
#     export DB_PASSWORD='YourStrongPassw0rd!'
#     ./build.sh
#
#   ※ NATゲートウェイ・ALB・RDS Multi-AZ は待機中も課金されます。検証後は必ず ./cleanup.sh を実行してください。
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# 変数定義(必要に応じて書き換えてください)
# ---------------------------------------------------------------------------
REGION="${REGION:-ap-northeast-1}"          # 東京リージョン
AZ_A="ap-northeast-1a"
AZ_C="ap-northeast-1c"
NAME_PREFIX="ha"                            # README のリソース名に合わせた接頭辞
INSTANCE_TYPE="t3.micro"                    # EC2 のインスタンスタイプ
DB_INSTANCE_CLASS="db.t3.micro"             # RDS のインスタンスクラス
DB_USERNAME="${DB_USERNAME:?環境変数 DB_USERNAME を設定してください(例: export DB_USERNAME=admin)}"
DB_PASSWORD="${DB_PASSWORD:?環境変数 DB_PASSWORD を設定してください(8文字以上)}"

VPC_CIDR="10.0.0.0/16"
STATE_FILE="$(cd "$(dirname "$0")" && pwd)/.handson-state.env"
USER_DATA_FILE="$(cd "$(dirname "$0")" && pwd)/user-data.sh"

export AWS_DEFAULT_REGION="$REGION"

# 状態ファイルに key=value を追記する関数(cleanup.sh で読み込みます)
save() {
  echo "$1=$2" >> "$STATE_FILE"
}

# 既存の状態ファイルがあれば二重作成を防ぐため中断する
if [[ -f "$STATE_FILE" ]]; then
  echo "エラー: $STATE_FILE が既に存在します。前回のリソースが残っている可能性があります。"
  echo "       先に ./cleanup.sh を実行するか、状態ファイルを削除してください。"
  exit 1
fi
: > "$STATE_FILE"
save REGION "$REGION"
save NAME_PREFIX "$NAME_PREFIX"

echo "=== [フェーズ1] VPC とサブネットを作成します ==="

# --- VPC ---
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block "$VPC_CIDR" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${NAME_PREFIX}-three-tier-vpc}]" \
  --query 'Vpc.VpcId' --output text)
save VPC_ID "$VPC_ID"
# RDS のエンドポイント名前解決などに必要なため DNS ホスト名を有効化
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}'
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support '{"Value":true}'
echo "VPC: $VPC_ID"

# --- サブネット(README のサブネット設計表と同じ 6 つ) ---
create_subnet() {
  # 引数: 名前 CIDR AZ
  aws ec2 create-subnet \
    --vpc-id "$VPC_ID" \
    --cidr-block "$2" \
    --availability-zone "$3" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$1}]" \
    --query 'Subnet.SubnetId' --output text
}
SUBNET_PUBLIC_A=$(create_subnet public-1a       10.0.1.0/24  "$AZ_A")
SUBNET_PUBLIC_C=$(create_subnet public-1c       10.0.2.0/24  "$AZ_C")
SUBNET_APP_A=$(create_subnet    private-app-1a  10.0.11.0/24 "$AZ_A")
SUBNET_APP_C=$(create_subnet    private-app-1c  10.0.12.0/24 "$AZ_C")
SUBNET_DB_A=$(create_subnet     private-db-1a   10.0.21.0/24 "$AZ_A")
SUBNET_DB_C=$(create_subnet     private-db-1c   10.0.22.0/24 "$AZ_C")
save SUBNET_PUBLIC_A "$SUBNET_PUBLIC_A"
save SUBNET_PUBLIC_C "$SUBNET_PUBLIC_C"
save SUBNET_APP_A "$SUBNET_APP_A"
save SUBNET_APP_C "$SUBNET_APP_C"
save SUBNET_DB_A "$SUBNET_DB_A"
save SUBNET_DB_C "$SUBNET_DB_C"

# パブリックサブネットはパブリック IPv4 の自動割り当てを有効化(手順3)
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_PUBLIC_A" --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_PUBLIC_C" --map-public-ip-on-launch
echo "サブネット 6 つを作成しました"

echo "=== [フェーズ2] インターネットゲートウェイとパブリックルートテーブル ==="

# --- IGW(手順4) ---
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${NAME_PREFIX}-three-tier-igw}]" \
  --query 'InternetGateway.InternetGatewayId' --output text)
save IGW_ID "$IGW_ID"
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

# --- パブリックルートテーブル ha-public-rt(手順5) ---
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${NAME_PREFIX}-public-rt}]" \
  --query 'RouteTable.RouteTableId' --output text)
save PUBLIC_RT_ID "$PUBLIC_RT_ID"
aws ec2 create-route --route-table-id "$PUBLIC_RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" > /dev/null
aws ec2 associate-route-table --route-table-id "$PUBLIC_RT_ID" --subnet-id "$SUBNET_PUBLIC_A" > /dev/null
aws ec2 associate-route-table --route-table-id "$PUBLIC_RT_ID" --subnet-id "$SUBNET_PUBLIC_C" > /dev/null
echo "IGW: $IGW_ID / パブリックRT: $PUBLIC_RT_ID"

echo "=== [フェーズ3] NATゲートウェイ(public-1a)とプライベートAPPルートテーブル ==="

# --- Elastic IP + NATゲートウェイ(手順6) ---
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${NAME_PREFIX}-nat-eip}]" \
  --query 'AllocationId' --output text)
save EIP_ALLOC_ID "$EIP_ALLOC_ID"

NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id "$SUBNET_PUBLIC_A" \
  --allocation-id "$EIP_ALLOC_ID" \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${NAME_PREFIX}-nat-gw}]" \
  --query 'NatGateway.NatGatewayId' --output text)
save NAT_GW_ID "$NAT_GW_ID"
echo "NATゲートウェイ $NAT_GW_ID が利用可能になるまで待機します(数分かかります)..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID"

# --- プライベートAPPルートテーブル ha-private-app-rt(手順7) ---
#     DB サブネットにはインターネット経路が不要なので関連付けません
PRIVATE_APP_RT_ID=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${NAME_PREFIX}-private-app-rt}]" \
  --query 'RouteTable.RouteTableId' --output text)
save PRIVATE_APP_RT_ID "$PRIVATE_APP_RT_ID"
aws ec2 create-route --route-table-id "$PRIVATE_APP_RT_ID" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT_GW_ID" > /dev/null
aws ec2 associate-route-table --route-table-id "$PRIVATE_APP_RT_ID" --subnet-id "$SUBNET_APP_A" > /dev/null
aws ec2 associate-route-table --route-table-id "$PRIVATE_APP_RT_ID" --subnet-id "$SUBNET_APP_C" > /dev/null
echo "NAT: $NAT_GW_ID / プライベートAPP RT: $PRIVATE_APP_RT_ID"

echo "=== [フェーズ4] セキュリティグループを3層で作成 ==="

# --- ALB用SG ha-alb-sg(手順8): 0.0.0.0/0 から 80/443 ---
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name "${NAME_PREFIX}-alb-sg" \
  --description "ALB SG: allow HTTP/HTTPS from anywhere" \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${NAME_PREFIX}-alb-sg}]" \
  --query 'GroupId' --output text)
save ALB_SG_ID "$ALB_SG_ID"
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG_ID" --protocol tcp --port 80  --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null

# --- EC2用SG ha-app-sg(手順9): ソースは ha-alb-sg(IPではなくSGを信頼する) ---
APP_SG_ID=$(aws ec2 create-security-group \
  --group-name "${NAME_PREFIX}-app-sg" \
  --description "App SG: allow HTTP from ALB SG only" \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${NAME_PREFIX}-app-sg}]" \
  --query 'GroupId' --output text)
save APP_SG_ID "$APP_SG_ID"
aws ec2 authorize-security-group-ingress --group-id "$APP_SG_ID" --protocol tcp --port 80 --source-group "$ALB_SG_ID" > /dev/null

# --- RDS用SG ha-db-sg(手順10): ソースは ha-app-sg ---
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name "${NAME_PREFIX}-db-sg" \
  --description "DB SG: allow MySQL from App SG only" \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${NAME_PREFIX}-db-sg}]" \
  --query 'GroupId' --output text)
save DB_SG_ID "$DB_SG_ID"
aws ec2 authorize-security-group-ingress --group-id "$DB_SG_ID" --protocol tcp --port 3306 --source-group "$APP_SG_ID" > /dev/null
echo "SG: alb=$ALB_SG_ID app=$APP_SG_ID db=$DB_SG_ID"

echo "=== [フェーズ5] 起動テンプレートを作成 ==="

# --- 最新の Amazon Linux 2023 AMI ID を SSM パラメータストアから取得 ---
AMI_ID=$(aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query 'Parameter.Value' --output text)
echo "AMI: $AMI_ID"

# --- ユーザーデータを base64 化して起動テンプレートに埋め込む(手順11〜12) ---
USER_DATA_B64=$(base64 -w 0 "$USER_DATA_FILE" 2>/dev/null || base64 "$USER_DATA_FILE" | tr -d '\n')
LT_NAME="${NAME_PREFIX}-app-launch-template"
LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name "$LT_NAME" \
  --launch-template-data "{
    \"ImageId\": \"${AMI_ID}\",
    \"InstanceType\": \"${INSTANCE_TYPE}\",
    \"SecurityGroupIds\": [\"${APP_SG_ID}\"],
    \"UserData\": \"${USER_DATA_B64}\",
    \"MetadataOptions\": {\"HttpTokens\": \"required\"},
    \"TagSpecifications\": [{\"ResourceType\": \"instance\", \"Tags\": [{\"Key\": \"Name\", \"Value\": \"${NAME_PREFIX}-app-instance\"}]}]
  }" \
  --query 'LaunchTemplate.LaunchTemplateId' --output text)
save LT_ID "$LT_ID"
save LT_NAME "$LT_NAME"
echo "起動テンプレート: $LT_ID"

echo "=== [フェーズ7] ターゲットグループと ALB を作成 ==="

# --- ターゲットグループ(手順18〜19): HTTP 80、ヘルスチェック /health.html ---
TG_ARN=$(aws elbv2 create-target-group \
  --name "${NAME_PREFIX}-app-tg" \
  --protocol HTTP --port 80 \
  --vpc-id "$VPC_ID" \
  --target-type instance \
  --health-check-protocol HTTP \
  --health-check-path /health.html \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
save TG_ARN "$TG_ARN"

# --- ALB ha-app-alb(手順20〜21): インターネット向け、パブリックサブネット 2 つ、ha-alb-sg ---
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "${NAME_PREFIX}-app-alb" \
  --scheme internet-facing \
  --type application \
  --subnets "$SUBNET_PUBLIC_A" "$SUBNET_PUBLIC_C" \
  --security-groups "$ALB_SG_ID" \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
save ALB_ARN "$ALB_ARN"
echo "ALB が利用可能になるまで待機します..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"

# --- リスナー HTTP:80 → ターゲットグループへ転送 ---
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=${TG_ARN}" \
  --query 'Listeners[0].ListenerArn' --output text)
save LISTENER_ARN "$LISTENER_ARN"
echo "ALB: $ALB_ARN"

echo "=== [フェーズ6] Auto Scaling Group を作成 ==="

# --- ASG ha-app-asg(手順13〜16): 最小2・希望2・最大4、プライベートAPPサブネット、ELB ヘルスチェック ---
ASG_NAME="${NAME_PREFIX}-app-asg"
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "$ASG_NAME" \
  --launch-template "LaunchTemplateId=${LT_ID},Version=\$Latest" \
  --min-size 2 --desired-capacity 2 --max-size 4 \
  --vpc-zone-identifier "${SUBNET_APP_A},${SUBNET_APP_C}" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB \
  --health-check-grace-period 300 \
  --tags "Key=Name,Value=${NAME_PREFIX}-app-instance,PropagateAtLaunch=true"
save ASG_NAME "$ASG_NAME"

# --- ターゲット追跡スケーリングポリシー(手順17): 平均CPU使用率 70% ---
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name "$ASG_NAME" \
  --policy-name "${NAME_PREFIX}-cpu-target-tracking" \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "PredefinedMetricSpecification": {"PredefinedMetricType": "ASGAverageCPUUtilization"},
    "TargetValue": 70.0
  }' > /dev/null
echo "ASG: $ASG_NAME"

echo "=== [フェーズ8] RDS(MySQL, Multi-AZ)を作成 ==="

# --- DBサブネットグループ ha-db-subnet-group(手順23) ---
DB_SUBNET_GROUP="${NAME_PREFIX}-db-subnet-group"
aws rds create-db-subnet-group \
  --db-subnet-group-name "$DB_SUBNET_GROUP" \
  --db-subnet-group-description "Subnet group for ${NAME_PREFIX} three tier RDS" \
  --subnet-ids "$SUBNET_DB_A" "$SUBNET_DB_C" > /dev/null
save DB_SUBNET_GROUP "$DB_SUBNET_GROUP"

# --- RDS インスタンス(手順24〜26): Multi-AZ、パブリックアクセスなし、ha-db-sg、gp3 20GB ---
DB_IDENTIFIER="${NAME_PREFIX}-mysql-db"
aws rds create-db-instance \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --engine mysql \
  --db-instance-class "$DB_INSTANCE_CLASS" \
  --allocated-storage 20 \
  --storage-type gp3 \
  --master-username "$DB_USERNAME" \
  --master-user-password "$DB_PASSWORD" \
  --multi-az \
  --no-publicly-accessible \
  --db-subnet-group-name "$DB_SUBNET_GROUP" \
  --vpc-security-group-ids "$DB_SG_ID" \
  --backup-retention-period 0 \
  --tags "Key=Name,Value=${DB_IDENTIFIER}" > /dev/null
save DB_IDENTIFIER "$DB_IDENTIFIER"
echo "RDS $DB_IDENTIFIER が利用可能になるまで待機します(Multi-AZ のため 10 分前後かかります)..."
aws rds wait db-instance-available --db-instance-identifier "$DB_IDENTIFIER"

# ---------------------------------------------------------------------------
# 結果表示
# ---------------------------------------------------------------------------
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' --output text)
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier "$DB_IDENTIFIER" \
  --query 'DBInstances[0].Endpoint.Address' --output text)
# レベル4(WordPress)のキットが利用する接続情報も保存する(パスワードは保存しない)
save RDS_ENDPOINT "$RDS_ENDPOINT"
save DB_USERNAME "$DB_USERNAME"

echo ""
echo "======================================================================"
echo " 構築が完了しました"
echo "----------------------------------------------------------------------"
echo " ALB DNS 名     : http://${ALB_DNS}"
echo " RDS エンドポイント : ${RDS_ENDPOINT}:3306"
echo "----------------------------------------------------------------------"
echo " ブラウザで ALB の URL を開き、リロードするたびに Instance ID が"
echo " 切り替わることを確認してください(ターゲットが healthy になるまで数分)。"
echo " 検証が終わったら必ず ./cleanup.sh を実行してください(課金が続きます)。"
echo "======================================================================"
