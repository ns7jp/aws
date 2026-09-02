#!/bin/bash
# =============================================================================
# user-data.sh
# EC2インスタンスの初回起動時に自動実行されるスクリプト(Amazon Linux 2023 用)
# ../README.md の「フェーズ5: Webサーバーソフトを入れて公開する」を自動化しています。
# 実行ログは /var/log/cloud-init-output.log で確認できます。
# =============================================================================
set -euxo pipefail

# --- 1. パッケージを更新し Apache(httpd) をインストール ---
dnf update -y
dnf install -y httpd

# --- 2. httpd を起動し、再起動後も自動起動するように設定 ---
systemctl enable --now httpd

# --- 3. IMDSv2 でインスタンスIDを取得 ---
# IMDSv2 はトークンを先に取得してからメタデータへアクセスする方式です(セキュリティ強化のため)。
TOKEN="$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")"
INSTANCE_ID="$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
  http://169.254.169.254/latest/meta-data/instance-id)"
AZ="$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)"

# --- 4. index.html を配置 ---
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>handson-web-server</title>
</head>
<body>
  <h1>Hello from my first EC2 web server!</h1>
  <p>Instance ID: ${INSTANCE_ID}</p>
  <p>Availability Zone: ${AZ}</p>
</body>
</html>
EOF
