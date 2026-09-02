# レベル4 ハンズオンキット(レベル3 との差分を自動構築)

このディレクトリは、[レベル4 のドキュメント](../README.md)で解説している WordPress 本番構成を、AWS CLI で再現するための実行キットです。レベル4 は**レベル3 の高可用性3層構成の上に差分を積む**設計なので、このキットも「差分キット」です。VPC・ALB・Auto Scaling・RDS は作成せず、[レベル3 のハンズオンキット](../../03-ha-three-tier/handson/README.md)が残した state ファイルを読み込んで、その上に WordPress・Secrets Manager・ElastiCache・S3・AWS Backup・監視を追加します。

> ⚠️ **未検証の注記**: このキットは実際の AWS 環境での通し実行を行っていません。コマンドはよく知られた AWS CLI v2 の構文で記述していますが、実行前に必ず内容を読み、料金と権限を理解したうえで自己責任でお使いください。

## 位置づけと前提条件

| 前提 | 内容 |
|---|---|
| レベル3 構築済み | `../../03-ha-three-tier/handson/build.sh` を実行し、`../../03-ha-three-tier/handson/.handson-state.env` が存在すること |
| AWS CLI v2 | `aws sts get-caller-identity` が成功する認証情報が設定済みであること |
| 必要ツール | `bash` `sed` `base64`(Linux / macOS / WSL を想定) |
| 権限 | Secrets Manager / IAM / ElastiCache / S3 / AWS Backup / CloudWatch / SNS / EC2 / Auto Scaling の作成・削除権限 |

### レベル3 state の変数名を確認してください

`build.sh` は、レベル3 キット(`../../03-ha-three-tier/handson/build.sh`)が保存する state ファイル `../../03-ha-three-tier/handson/.handson-state.env` を読み込みます。以下の変数を使用します(レベル3 側の変数名は `build.sh` 冒頭で自動的に読み替えます)。

| レベル3 state の変数名 | 意味 |
|---|---|
| `VPC_ID` | レベル3 の VPC ID |
| `SUBNET_DB_A` / `SUBNET_DB_C` | DATA層プライベートサブネット(Redis をここに置きます) |
| `APP_SG_ID` | App層 EC2 用 SG(`ha-app-sg`)。Redis SG の許可元になります |
| `ALB_ARN` | ALB の ARN(5XX アラームの対象) |
| `ASG_NAME` | Auto Scaling Group 名 |
| `LT_ID` | 起動テンプレート ID(新バージョンを追加します) |
| `DB_IDENTIFIER` | RDS の DB インスタンス識別子(Backup とアラームの対象) |
| `RDS_ENDPOINT` | RDS のエンドポイント(ホスト名) |
| `DB_USERNAME` | RDS のマスターユーザー名 |
| (環境変数)`DB_PASSWORD` | RDS のマスターパスワード。安全のため state には保存されないので、レベル3 構築時と同じ値を環境変数で渡してください |

## ファイルの役割

| ファイル | 役割 |
|---|---|
| `build.sh` | レベル3 state を読み込み、差分リソースを 8 ステップで作成します。作成した ID は `.handson-state.env` に保存します |
| `cleanup.sh` | `build.sh` が作ったものを逆順に削除し、ASG をレベル3 の起動テンプレートバージョンに戻します |
| `user-data-wordpress.sh` | EC2 起動時に実行されるスクリプト。PHP と WordPress 日本語版を導入し、Secrets Manager から認証情報を取得して `wp-config.php` を生成します。`__REGION__` などのプレースホルダーは `build.sh` が `sed` で埋めます |
| `policies/ec2-trust-policy.json` | EC2 がロールを引き受けるための信頼ポリシー |
| `policies/backup-trust-policy.json` | AWS Backup がロールを引き受けるための信頼ポリシー |
| `policies/secrets-read-policy.template.json` | `secretsmanager:GetSecretValue` を該当シークレットの ARN のみに許可する最小権限ポリシー |
| `policies/media-s3-policy.template.json` | メディア用バケットに限定した S3 読み書き権限 |
| `.gitignore` | `.handson-state.env` と描画済みユーザーデータをコミットしないための設定 |

## build.sh が作成するもの

1. **Secrets Manager**: `wordpress/prod/db` に `{"username","password","host","dbname"}` の JSON を保管
2. **S3**: `wp-prod-media-<アカウントID>` バケット(パブリックアクセスブロックは有効のまま)
3. **IAM**: EC2 用ロール + インスタンスプロファイル(シークレット読み取り・メディアバケット読み書き・`AmazonSSMManagedInstanceCore`)
4. **ElastiCache**: Redis 用 SG(6379 を App SG からのみ許可)、サブネットグループ、`cache.t3.micro` 1 ノードのクラスター
5. **AWS Backup**: ボールト、毎日 03:00 JST(`cron(0 18 * * ? *)` UTC)・30 日保持のプラン、RDS を対象にしたセレクションと専用 IAM ロール
6. **SNS + CloudWatch Alarm**: メール購読トピックと 3 つのアラーム(ASG 平均 CPU > 80%、RDS FreeStorageSpace < 2GiB、ALB `HTTPCode_ELB_5XX_Count` ≥ 10 件/5分)
7. **起動テンプレート**: `user-data-wordpress.sh` とインスタンスプロファイルを載せた新バージョンを追加し、デフォルトに設定
8. **ASG**: 新バージョンに切り替えてインスタンスリフレッシュを開始

## 実行手順

```bash
cd projects/04-wordpress-production/handson

# 1. レベル3 state の変数名を確認する
cat ../../03-ha-three-tier/handson/.handson-state.env

# 2. 通知先メールアドレスを指定して構築する(DB_PASSWORD が state に無い場合は併せて指定)
ALERT_EMAIL="you@example.com" ./build.sh
# 例: ALERT_EMAIL="you@example.com" DB_PASSWORD="xxxx" ./build.sh

# 3. メールで届く SNS の「Confirm subscription」を承認する

# 4. インスタンスリフレッシュの完了を待つ(5〜10 分)
aws autoscaling describe-instance-refreshes --auto-scaling-group-name <ASG_NAME>

# 5. 表示された ALB の URL をブラウザで開き、WordPress の初期設定を進める
```

WordPress 管理画面にログインしたら、レベル4 ドキュメントのフェーズ3・4 に沿って「Redis Object Cache」と S3 オフロード用プラグインを有効化してください。`wp-config.php` には `WP_REDIS_HOST` と `AS3CF_SETTINGS`(バケット名・リージョン・IAM ロール利用)があらかじめ書き込まれています。

任意で上書きできる環境変数は次の通りです。

| 変数 | 既定値 | 用途 |
|---|---|---|
| `AWS_DEFAULT_REGION` | `ap-northeast-1` | 構築先リージョン |
| `PREFIX` | `wp-prod` | リソース名の接頭辞 |
| `SECRET_NAME` | `wordpress/prod/db` | シークレット名 |
| `WP_DB_NAME` | `wordpress` | WordPress 用データベース名(起動時に無ければ作成します) |
| `CACHE_NODE_TYPE` | `cache.t3.micro` | Redis ノードタイプ |

## Secrets Manager の値を確認する方法

パスワードそのものはコードにもサーバーにも書かれていません。確認したいときは、権限を持つ自分の端末から次のコマンドで取り出します。

```bash
aws secretsmanager get-secret-value \
  --secret-id wordpress/prod/db \
  --query SecretString --output text | jq .
```

EC2 側で正しく取得できているかは、Session Manager で接続して `sudo grep DB_HOST /var/www/html/wp-config.php` を実行すると確認できます(`AmazonSSMManagedInstanceCore` を付与しているので SSH 鍵は不要です)。

## 💰 コストの注意

- **ElastiCache には無料利用枠がありません**。`cache.t3.micro` でも作成した瞬間から時間課金が始まります。検証が終わったら同日中に `cleanup.sh` を実行してください。
- レベル3 の ALB・NAT ゲートウェイ・RDS Multi-AZ も引き続き課金されます。`cleanup.sh` はレベル4 の差分だけを消すので、完全に止めるには続けて `../../03-ha-three-tier/handson/cleanup.sh` を実行してください。
- AWS Backup の復旧ポイントは保管量に応じて課金されます。`cleanup.sh` はボールト内の復旧ポイントも削除します。
- 課金事故を防ぐ考え方は [コスト管理ガイド](../../../docs/03-cost-management.md) にまとめています。事前に Billing Alarm を設定しておくことを強くおすすめします。

## 削除手順

```bash
cd projects/04-wordpress-production/handson
./cleanup.sh
```

`cleanup.sh` は次の順で削除します: ASG を旧バージョンに戻してリフレッシュ → アラーム・SNS → Backup(セレクション・プラン・復旧ポイント・ボールト・ロール)→ ElastiCache(クラスター・サブネットグループ・SG)→ EC2 用 IAM → S3(中身ごと)→ シークレット(即時削除)。途中で失敗した項目は `(skip)` と表示して続行するので、最後にコンソールで残骸が無いか確認してください。

## トラブルシューティング

| 症状 | 確認ポイント |
|---|---|
| `build.sh` が最初のチェックで止まる | レベル3 state の変数名。表の名前と一致しているか確認し、必要なら `build.sh` のチェック箇所で読み替える |
| インスタンスリフレッシュ後もターゲットが Unhealthy | ユーザーデータのログ `/var/log/cloud-init-output.log` を Session Manager で確認。Secrets Manager 取得失敗なら IAM ポリシーの ARN、DB 作成失敗なら RDS SG の 3306 許可元を疑う |
| `Error establishing a database connection` | シークレットの `host` がレベル3 の RDS エンドポイントと一致しているか、`DB_PASSWORD` が正しいか |
| Redis Object Cache が接続できない | Redis SG の 6379 の許可元が `APP_SG_ID` になっているか、`WP_REDIS_HOST` の値が `.handson-state.env` の `REDIS_HOST` と一致するか |

## 関連ドキュメント

- [レベル4 の解説ドキュメント](../README.md)
- [レベル3 ハンズオンキット(前提となる土台)](../../03-ha-three-tier/handson/README.md)
- [コスト管理と無料利用枠ガイド](../../../docs/03-cost-management.md)
