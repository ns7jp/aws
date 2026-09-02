#!/bin/bash
# レベル4: WordPress 用ユーザーデータ(Amazon Linux 2023 向け)
# build.sh が __PLACEHOLDER__ を sed で埋めてから起動テンプレートに登録します。
set -euo pipefail

REGION="__REGION__"
SECRET_ID="__SECRET_ID__"
REDIS_HOST="__REDIS_HOST__"
MEDIA_BUCKET="__MEDIA_BUCKET__"

# --- 1. パッケージ導入 -------------------------------------------------------
dnf update -y
dnf install -y httpd php php-mysqlnd php-fpm php-gd php-mbstring php-xml php-json \
  wget tar jq mariadb105

systemctl enable --now httpd php-fpm

# ALB のヘルスチェック用ファイル(レベル3 と同じパス /health.html)
echo "OK" > /var/www/html/health.html

# --- 2. Secrets Manager から DB 認証情報を取得(IAM ロール経由・パスワード直書きなし)
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "${REGION}" \
  --secret-id "${SECRET_ID}" \
  --query SecretString \
  --output text)

DB_USER=$(echo "${SECRET_JSON}" | jq -r '.username')
DB_PASSWORD=$(echo "${SECRET_JSON}" | jq -r '.password')
DB_HOST=$(echo "${SECRET_JSON}" | jq -r '.host')
DB_NAME=$(echo "${SECRET_JSON}" | jq -r '.dbname')

# WordPress 用データベースが無ければ作成する(既にあれば何もしない)
mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" \
  -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# --- 3. WordPress 日本語版を取得して配置 ------------------------------------
cd /tmp
wget -q https://ja.wordpress.org/latest-ja.tar.gz
tar -xzf latest-ja.tar.gz
cp -a wordpress/. /var/www/html/
rm -rf /tmp/wordpress /tmp/latest-ja.tar.gz

# --- 4. wp-config.php を生成 ------------------------------------------------
SALTS=$(wget -q -O - https://api.wordpress.org/secret-key/1.1/salt/)

cat > /var/www/html/wp-config.php <<EOF
<?php
define( 'DB_NAME', '${DB_NAME}' );
define( 'DB_USER', '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASSWORD}' );
define( 'DB_HOST', '${DB_HOST}' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

${SALTS}

\$table_prefix = 'wp_';

/* ElastiCache for Redis(Redis Object Cache プラグイン用) */
define( 'WP_REDIS_HOST', '${REDIS_HOST}' );
define( 'WP_REDIS_PORT', 6379 );

/* S3 メディアオフロード用プラグインが参照する値 */
define( 'AS3CF_SETTINGS', serialize( array(
    'provider' => 'aws',
    'use-server-roles' => true,
    'bucket' => '${MEDIA_BUCKET}',
    'region' => '${REGION}',
) ) );

/* ALB 配下(HTTP 終端)でもサイト URL を正しく扱う */
if ( isset( \$_SERVER['HTTP_X_FORWARDED_PROTO'] ) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    \$_SERVER['HTTPS'] = 'on';
}

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

# --- 5. 権限と再起動 ----------------------------------------------------------
chown -R apache:apache /var/www/html
chmod 640 /var/www/html/wp-config.php
systemctl restart php-fpm httpd
