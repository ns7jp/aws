#!/bin/bash
# EC2起動時に自動実行されるユーザーデータ(README フェーズ5 手順12 と同じ内容)
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

# ALBのヘルスチェックが見に来る専用ファイル
echo "OK" > /var/www/html/health.html

# どのインスタンスが応答しているかを確認するためのページ
# IMDSv2(トークン方式)でインスタンスメタデータを取得する
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" http://169.254.169.254/latest/meta-data/instance-id)
echo "<h1>Hello from Auto Scaling! Instance ID: ${INSTANCE_ID}</h1>" > /var/www/html/index.html
