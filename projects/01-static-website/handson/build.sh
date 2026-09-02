#!/usr/bin/env bash
# =============================================================================
# レベル1: 静的Webサイト公開環境(S3 + CloudFront + OAC)構築スクリプト
#
# 本編 ../README.md の STEP1〜STEP3 を AWS CLI v2 で自動化したものです。
# STEP4(ACM)・STEP5(Route 53)は DOMAIN が空なら実行しません(末尾の案内を参照)。
#
# ⚠️ 実行するとAWS利用料が発生する可能性があります。
# ⚠️ このスクリプトは実AWS環境で未検証です。実行前に必ず内容を読んでください。
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# ▼▼▼ ここを編集してください ▼▼▼
# -----------------------------------------------------------------------------
# S3バケット名(世界中で一意。すべて小文字・ハイフン区切り。例: your-portfolio-site-2026)
BUCKET_NAME="your-portfolio-site-2026"

# S3バケットを作成するリージョン(本編では東京 ap-northeast-1 を使用)
REGION="ap-northeast-1"

# 独自ドメイン(任意)。例: "www.example.com"
# 空文字のままなら CloudFront の既定ドメイン(xxxx.cloudfront.net)で公開します。
DOMAIN=""
# -----------------------------------------------------------------------------
# ▲▲▲ ここまで ▲▲▲
# -----------------------------------------------------------------------------

# スクリプト自身のあるディレクトリ(どこから実行しても相対パスが壊れないように)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="${SCRIPT_DIR}/site"
WORK_DIR="${SCRIPT_DIR}/.work"
mkdir -p "${WORK_DIR}"

# 後片付け(cleanup.sh)で使うため、作成したリソースのIDをこのファイルに記録します
STATE_FILE="${SCRIPT_DIR}/.state"

echo "=============================================="
echo " 静的Webサイト構築を開始します"
echo "   BUCKET_NAME : ${BUCKET_NAME}"
echo "   REGION      : ${REGION}"
echo "   DOMAIN      : ${DOMAIN:-(未設定: cloudfront.net ドメインで公開)}"
echo "=============================================="

# 認証情報の確認(aws configure が済んでいるか)
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
echo "[確認] AWSアカウントID: ${ACCOUNT_ID}"

# -----------------------------------------------------------------------------
# STEP1: S3バケットの作成(パブリックアクセスは全てブロックのまま)
# -----------------------------------------------------------------------------
echo ""
echo "[STEP1] S3バケットを作成します: ${BUCKET_NAME}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "  -> バケットは既に存在します(スキップ)"
else
  # us-east-1 以外は LocationConstraint の指定が必須です
  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  echo "  -> 作成しました"
fi

# 本編STEP1-4: 「パブリックアクセスをすべてブロック」を明示的に維持します(ここが一番大事)
echo "[STEP1] パブリックアクセスブロック(4項目すべてON)を設定します"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
# 注意: 本編STEP1-6 のとおり「静的ウェブサイトホスティング」は有効化しません。

echo "BUCKET_NAME=${BUCKET_NAME}" >  "${STATE_FILE}"
echo "REGION=${REGION}"           >> "${STATE_FILE}"

# -----------------------------------------------------------------------------
# STEP2: index.html / error.html のアップロード
# -----------------------------------------------------------------------------
echo ""
echo "[STEP2] サイトのファイルをアップロードします(${SITE_DIR})"
aws s3 cp "${SITE_DIR}/index.html" "s3://${BUCKET_NAME}/index.html" --content-type "text/html; charset=utf-8"
aws s3 cp "${SITE_DIR}/error.html" "s3://${BUCKET_NAME}/error.html" --content-type "text/html; charset=utf-8"
echo "  -> アップロード完了"

# -----------------------------------------------------------------------------
# STEP3-a: OAC(Origin Access Control)の作成
#   CloudFrontだけがS3にアクセスできるようにする「専用通行証」です。署名方式は SigV4。
# -----------------------------------------------------------------------------
echo ""
echo "[STEP3] OAC(Origin Access Control)を作成します"
OAC_NAME="oac-${BUCKET_NAME}"
OAC_ID="$(aws cloudfront create-origin-access-control \
  --origin-access-control-config \
    "Name=${OAC_NAME},Description=OAC for ${BUCKET_NAME},SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3" \
  --query 'OriginAccessControl.Id' --output text)"
echo "  -> OAC ID: ${OAC_ID}"
echo "OAC_ID=${OAC_ID}" >> "${STATE_FILE}"

# -----------------------------------------------------------------------------
# STEP3-b: CloudFrontディストリビューションの作成
#   テンプレート(cloudfront-config.template.json)のプレースホルダを sed で埋めます。
#   - デフォルトルートオブジェクト : index.html
#   - Viewer Protocol Policy       : redirect-to-https(HTTP→HTTPSへ強制リダイレクト)
#   - 許可メソッド                 : GET, HEAD のみ
# -----------------------------------------------------------------------------
echo "[STEP3] CloudFrontディストリビューションを作成します"
CALLER_REFERENCE="${BUCKET_NAME}-$(date +%s)"   # 二重作成防止用の一意な文字列
CF_CONFIG="${WORK_DIR}/cloudfront-config.json"
sed \
  -e "s|BUCKET_NAME|${BUCKET_NAME}|g" \
  -e "s|REGION|${REGION}|g" \
  -e "s|OAC_ID|${OAC_ID}|g" \
  -e "s|CALLER_REFERENCE|${CALLER_REFERENCE}|g" \
  "${SCRIPT_DIR}/cloudfront-config.template.json" > "${CF_CONFIG}"

# 作成結果から ID / ドメイン名 / ARN をタブ区切りで受け取ります
read -r DISTRIBUTION_ID DISTRIBUTION_DOMAIN DISTRIBUTION_ARN < <(
  aws cloudfront create-distribution \
    --distribution-config "file://${CF_CONFIG}" \
    --query 'Distribution.[Id,DomainName,ARN]' --output text
)
echo "  -> Distribution ID     : ${DISTRIBUTION_ID}"
echo "  -> Distribution Domain : ${DISTRIBUTION_DOMAIN}"
echo "DISTRIBUTION_ID=${DISTRIBUTION_ID}" >> "${STATE_FILE}"
echo "DISTRIBUTION_DOMAIN=${DISTRIBUTION_DOMAIN}" >> "${STATE_FILE}"

# -----------------------------------------------------------------------------
# STEP3-c: S3バケットポリシーの適用(本編STEP3-4「ポリシーをコピー」に相当)
#   Principal を cloudfront.amazonaws.com、Condition の AWS:SourceArn を
#   今作ったディストリビューションのARNに限定します。
#   → 「このディストリビューション経由のCloudFrontだけが読める」状態になります。
# -----------------------------------------------------------------------------
echo ""
echo "[STEP3] S3バケットポリシー(OAC用)を適用します"
BUCKET_POLICY="${WORK_DIR}/bucket-policy.json"
sed \
  -e "s|BUCKET_NAME|${BUCKET_NAME}|g" \
  -e "s|DISTRIBUTION_ARN|${DISTRIBUTION_ARN}|g" \
  "${SCRIPT_DIR}/bucket-policy.template.json" > "${BUCKET_POLICY}"
aws s3api put-bucket-policy --bucket "${BUCKET_NAME}" --policy "file://${BUCKET_POLICY}"
echo "  -> 適用完了"

# -----------------------------------------------------------------------------
# デプロイ完了待ち(数分〜十数分かかります)
# -----------------------------------------------------------------------------
echo ""
echo "[待機] ディストリビューションのデプロイ完了を待ちます(数分〜十数分)..."
aws cloudfront wait distribution-deployed --id "${DISTRIBUTION_ID}"
echo "  -> デプロイ完了(ステータス: Deployed)"

# -----------------------------------------------------------------------------
# STEP4 / STEP5: 独自ドメイン(ACM + Route 53)
#   DOMAIN が空ならスキップします。
#   設定する場合はコンソールで行うのが確実です(本編 ../README.md STEP4・STEP5 参照)。
#     1. ACM: 必ず us-east-1(バージニア北部)で証明書をリクエスト(DNS検証)
#     2. CloudFront: 代替ドメイン名(CNAME)と カスタムSSL証明書 を設定
#     3. Route 53: A レコード(エイリアス)でCloudFrontを指定
# -----------------------------------------------------------------------------
echo ""
if [[ -z "${DOMAIN}" ]]; then
  echo "[STEP4/5] DOMAIN が未設定のため、ACM / Route 53 の設定はスキップします"
else
  echo "[STEP4/5] 独自ドメイン ${DOMAIN} の設定は本スクリプトでは自動化していません。"
  echo "  以下をコンソールで実施してください(詳細は ../README.md STEP4・STEP5):"
  echo "   1. ACM(us-east-1!)で ${DOMAIN} の証明書をリクエストし、DNS検証を完了する"
  echo "   2. CloudFront ディストリビューション ${DISTRIBUTION_ID} に"
  echo "      代替ドメイン名 ${DOMAIN} と上記証明書を設定する"
  echo "   3. Route 53 のホストゾーンで A レコード(エイリアス)→ ${DISTRIBUTION_DOMAIN} を作成する"
fi

# -----------------------------------------------------------------------------
# 完了
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo " 構築が完了しました!"
echo "   URL: https://${DISTRIBUTION_DOMAIN}/"
echo ""
echo " 動作確認例:"
echo "   curl -I https://${DISTRIBUTION_DOMAIN}/          # 200 と x-cache ヘッダーを確認"
echo "   curl -I http://${DISTRIBUTION_DOMAIN}/           # 301 で https へリダイレクト"
echo "   curl -I https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/index.html  # 403(直接は見えない)"
echo ""
echo " 作成したリソースIDは ${STATE_FILE} に保存しました。"
echo " 不要になったら必ず ./cleanup.sh で削除してください(課金防止)。"
echo "=============================================="
