# ハンズオンキット: 静的Webサイト公開環境を AWS CLI で構築する

本編([../README.md](../README.md))ではマネジメントコンソールでの手順を説明しています。このディレクトリには、その STEP1〜STEP3(S3バケット作成 → ファイルアップロード → CloudFront + OAC 設定)を **AWS CLI v2 のシェルスクリプトで再現するキット**を置いています。

> ⚠️ **このスクリプトは実AWS環境で未検証のため、実行前に必ず内容を読み、検証後は削除してください。**
> 学習用の雛形として用意したものです。1行ずつ「何をしているか」を確認しながら進めることをおすすめします。

## 前提

- AWS CLI v2 がインストール済みであること(`aws --version` で `aws-cli/2.x` と表示される)
- `aws configure` で本編 STEP0 の IAM ユーザー(`portfolio-builder`)の認証情報とデフォルトリージョンを設定済みであること
- `bash` と `python3` が使えること(cleanup.sh で JSON の編集に python3 を使います)
- 独自ドメインは**任意**です。無くても CloudFront の既定ドメイン(`xxxx.cloudfront.net`)で公開できます

## ファイルの役割

| ファイル | 役割 |
|---|---|
| `build.sh` | S3バケット作成 → HTMLアップロード → OAC作成 → CloudFrontディストリビューション作成 → バケットポリシー適用 までを一括実行します |
| `cleanup.sh` | `build.sh` が作ったリソースを逆順に削除します(課金を止めるために必ず実行してください) |
| `site/index.html` | 公開するトップページ(日本語のシンプルなポートフォリオページ) |
| `site/error.html` | 存在しないURLにアクセスされたときに表示するエラーページ |
| `bucket-policy.template.json` | OAC 用の S3 バケットポリシーのテンプレート。`BUCKET_NAME` と `DISTRIBUTION_ARN` を `build.sh` が sed で埋めます |
| `cloudfront-config.template.json` | `aws cloudfront create-distribution` に渡す設定のテンプレート。`BUCKET_NAME` / `REGION` / `OAC_ID` / `CALLER_REFERENCE` を `build.sh` が埋めます |
| `.state`(実行時に生成) | 作成したリソースのIDを記録するファイル。`cleanup.sh` が参照します |
| `.work/`(実行時に生成) | テンプレートを埋めた後の JSON など、作業用ファイルの置き場です |

## 実行手順

### 1. 実行権限を付ける

```bash
cd projects/01-static-website/handson
chmod +x build.sh cleanup.sh
```

### 2. 変数を編集する

`build.sh` の先頭にある「ここを編集してください」ブロックを書き換えます。

| 変数 | 説明 |
|---|---|
| `BUCKET_NAME` | S3バケット名。世界中で一意である必要があるため、本編と同じく `your-portfolio-site-2026` のように末尾に数字を付けて自分だけの名前にしてください(すべて小文字・ハイフン区切り) |
| `REGION` | バケットを作るリージョン。本編どおり東京 `ap-northeast-1` が初期値です |
| `DOMAIN` | 独自ドメイン(任意)。空のままなら ACM / Route 53 の手順はスキップされます |

### 3. 構築する

```bash
./build.sh
```

進捗が `[STEP1]` `[STEP2]` `[STEP3]` の順に表示されます。最後の「デプロイ完了待ち」は数分〜十数分かかりますので、そのまま待ってください。完了すると公開URL(`https://xxxx.cloudfront.net/`)が表示されます。

### 4. 動作確認する

`build.sh` の最後に表示されるURLを使って、本編 STEP7 と同じ確認をします。

```bash
# 200 が返り、x-cache ヘッダーが付いていれば CloudFront 経由で配信されています
curl -I https://xxxx.cloudfront.net/

# http でアクセスすると 301 で https にリダイレクトされます
curl -I http://xxxx.cloudfront.net/

# S3 に直接アクセスすると 403 になります(裏口が閉じている証拠です)
curl -I https://<BUCKET_NAME>.s3.ap-northeast-1.amazonaws.com/index.html

# 存在しないパスは error.html が返ります
curl https://xxxx.cloudfront.net/nothing
```

ブラウザで開いて鍵アイコン(HTTPS)が表示されることも確認しましょう。

### 5. 独自ドメインを使う場合(任意・コンソール作業)

`DOMAIN` を設定しても、ACM 証明書の発行と Route 53 のレコード作成はスクリプトでは自動化していません。`build.sh` の最後に案内が出ますので、本編の [STEP4(ACM)](../README.md#step4-acmでのssltls証明書発行必ずus-east-1で) と [STEP5(Route 53)](../README.md#step5-route-53でのドメイン設定) に従ってコンソールで設定してください。証明書は**必ず us-east-1(バージニア北部)**で発行する点にご注意ください。

### 6. 後片付けする

```bash
./cleanup.sh
```

確認プロンプトで `yes` と入力すると、ディストリビューションの無効化(反映待ちで数分〜十数分)→ 削除 → OAC 削除 → S3 バケットを空にして削除、の順に進みます。

## ⚠️ 課金についての注意

- このキットで作るリソースは無料利用枠の範囲に収まることが多いですが、**リソースを残したままにすると課金され続ける可能性があります**。試し終わったら必ず `./cleanup.sh` を実行してください。
- 独自ドメインを設定した場合、Route 53 のホストゾーン(約0.5USD/月)と ACM 証明書は `cleanup.sh` では削除しません。コンソールから手動で削除してください。
- `cleanup.sh` の実行後は、AWS Billing コンソールで料金が発生していないか確認する習慣をつけましょう。詳しくは [コスト管理ガイド](../../../docs/03-cost-management.md) を参照してください。

## 関連ドキュメント

- [本編: レベル1 静的Webサイト公開環境の構築](../README.md)
- [コスト管理ガイド](../../../docs/03-cost-management.md)
