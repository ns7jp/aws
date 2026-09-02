# レベル6 ハンズオンキット: Terraform + CodePipeline で VPC/EC2 を自動構築する

[../README.md](../README.md) に掲載している Terraform のサンプルコードを、そのまま実行できる形のファイルに落とし込んだキットです。レベル2([../../02-ec2-web-server/README.md](../../02-ec2-web-server/README.md))で手作業構築した「VPC + パブリックサブネット + Apache 稼働 EC2」を、コードで再現します。

> ⚠️ **注記**: このキットは**実際の AWS 環境では未検証**です。`terraform fmt` による HCL 構文チェック(および目視レビュー)のみ行っており、`terraform validate` / `plan` / `apply` は実行していません。実行時にエラーが出た場合は、エラーメッセージを手掛かりに修正しながら進めてください(それ自体が良い学習になります)。

## 前提条件

| 項目 | 内容 |
|---|---|
| Terraform | 1.6 以上(`terraform version` で確認) |
| AWS CLI | v2 推奨。`aws configure` で認証情報とデフォルトリージョン `ap-northeast-1` を設定済みであること |
| IAM 権限 | S3 / DynamoDB / VPC / EC2 を作成・削除できる権限(学習用の個人アカウントを想定) |
| 自分のグローバル IP | `curl -s https://checkip.amazonaws.com` で確認しておく(SSH 許可用) |

## ディレクトリ構成

```text
handson/
├── README.md                     # このファイル
├── .gitignore                    # tfstate / tfvars / .terraform を除外
├── bootstrap/                    # 【最初に実行】tfstate 保存用 S3 + DynamoDB(ローカル state)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/                      # 再利用可能な部品
│   ├── vpc/                      # VPC 10.0.0.0/16、パブリックサブネット 10.0.1.0/24、IGW、ルートテーブル
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security_group/           # Web SG(22: 自分IPのみ、80/443: 全公開)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/                      # Amazon Linux 2023 + httpd、t3.micro、Elastic IP
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   └── dev/                      # modules を組み合わせる dev 環境
│       ├── main.tf               # モジュール呼び出し、provider、required_providers
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf            # tfstate 保存先(S3 backend)
│       └── terraform.tfvars.example
└── cicd/                         # CodeBuild 用 buildspec
    ├── buildspec-plan.yml        # terraform init / validate / plan
    └── buildspec-apply.yml       # 承認済み tfplan を apply
```

`../README.md` の設計との対応: 本キットでは EC2 モジュールからセキュリティグループを `modules/security_group` として分離し、Elastic IP を追加しています。AMI の取得は `data "aws_ami"` ではなく SSM パラメータストアの公開パラメータ(`/aws/service/ami-amazon-linux-latest/...`)を使う方式にしています。それ以外の変数名・値・リソース名は README のサンプルと揃えています。

## 実行手順

### ステップ1: state 管理基盤を作る(bootstrap)

tfstate の保存先となる S3 バケットと DynamoDB ロックテーブルを先に作ります。この段階では保存先がまだ無いので、`bootstrap/` 自身の state はローカルファイル(`bootstrap/terraform.tfstate`)に置きます。

```bash
cd projects/06-iac-cicd/handson/bootstrap

terraform init
# バケット名はグローバルで一意にする必要があります(例: handson-tfstate-yourname-20260101)
terraform plan  -var="tfstate_bucket_name=handson-tfstate-<自分のアカウント固有の文字列>"
terraform apply -var="tfstate_bucket_name=handson-tfstate-<自分のアカウント固有の文字列>"

terraform output
# tfstate_bucket_name = "handson-tfstate-..."
# lock_table_name     = "terraform-state-lock"
```

> ⚠️ **tfstate の取り扱い**: tfstate にはリソース ID や(RDS などを追加した場合)パスワードなどの機密情報が**平文**で記録されます。bootstrap の S3 バケットは「バージョニング有効」「SSE-S3 によるデフォルト暗号化」「パブリックアクセスすべてブロック」を設定済みですが、`bootstrap/terraform.tfstate` というローカルファイル自体も Git にコミットしないでください(`.gitignore` で除外済みです)。

### ステップ2: backend.tf にバケット名を反映する

`environments/dev/backend.tf` の `bucket` を、ステップ1の `tfstate_bucket_name` の値に書き換えます。backend ブロックでは変数が使えないため、直接記述する必要があります。

```hcl
bucket = "handson-tfstate-<自分のアカウント固有の文字列>"  # ← ここを書き換える
```

### ステップ3: 変数ファイルを用意する

```bash
cd ../environments/dev
cp terraform.tfvars.example terraform.tfvars
# my_ip_cidr を自分のグローバルIP(例: 203.0.113.10/32)に書き換える
```

`terraform.tfvars` は自分の IP を含むため `.gitignore` で除外しています。

### ステップ4: init / plan / apply

```bash
terraform init        # S3 backend への接続とプロバイダの取得
terraform validate    # 構文チェック
terraform plan -out=tfplan
# 出力の + / ~ / - を必ず目視確認する(今回はすべて + で、作成のみのはずです)

terraform apply tfplan
```

apply が完了すると `web_server_public_ip` が出力されます。

### ステップ5: 動作確認

```bash
# EC2 の user_data(httpd インストール)完了まで 1〜2 分待ってから実行
curl http://$(terraform output -raw web_server_public_ip)
# <h1>Hello from Terraform-managed EC2</h1> と表示されれば成功です
```

ブラウザで `http://<web_server_public_ip>` を開いても確認できます。マネジメントコンソールで VPC(`handson-dev-vpc`)、サブネット(`handson-dev-public-subnet-1a`)、EC2(`handson-dev-web-server`)が作成されていることも確認しておきましょう。

S3 コンソールで tfstate バケットを開くと `dev/terraform.tfstate` が保存されていること、DynamoDB テーブル `terraform-state-lock` に `LockID` の項目が(apply 中のみ)作られることも確認できます。

### ステップ6: 後片付け(destroy)

EC2 と Elastic IP は稼働中・確保中に課金されます。確認が終わったら必ず削除してください(コスト管理の詳細は [../../../docs/03-cost-management.md](../../../docs/03-cost-management.md) を参照)。

```bash
# dev 環境のリソースを削除
cd projects/06-iac-cicd/handson/environments/dev
terraform destroy

# 続けて state 管理基盤(S3 + DynamoDB)を削除
cd ../../bootstrap
terraform destroy -var="tfstate_bucket_name=handson-tfstate-<自分のアカウント固有の文字列>"
```

bootstrap の S3 バケットは `force_destroy = true` にしているため、中に tfstate(およびバージョニングされた過去版)が残っていても削除できます。削除後、`bootstrap/terraform.tfstate` などのローカルファイルも不要であれば消して構いません。

## CI/CD(CodePipeline + CodeBuild)について

`cicd/` には CodeBuild 用の buildspec を 2 つ用意しています。パイプライン自体の作成は Terraform 化せず、[../README.md](../README.md) の「フェーズ4」「フェーズ5」のコンソール手順に沿って作成してください。要点は次の通りです。

1. **IAM ロール** `codebuild-terraform-role` を最小権限で作成する(ポリシー例は `../README.md` フェーズ4)
2. **GitHub との接続**(CodeStar Connections)を作成する
3. **CodeBuild プロジェクト `terraform-plan`** を作成する
   - 環境イメージ: 標準イメージ(例: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`)で構いません。buildspec の install フェーズで Terraform バイナリをダウンロードします
   - buildspec: `projects/06-iac-cicd/handson/cicd/buildspec-plan.yml`
   - 出力アーティファクト名: `tfplan-artifact`
4. **CodeBuild プロジェクト `terraform-apply`** を作成する
   - buildspec: `projects/06-iac-cicd/handson/cicd/buildspec-apply.yml`
   - CodePipeline のアクション設定で、入力アーティファクトに Source と `tfplan-artifact` の**両方**を指定し、プライマリソースを Source にします(buildspec 内で `CODEBUILD_SRC_DIR_tfplan_artifact` から tfplan を取り出します)
5. **CodePipeline** を Source → Build(`terraform-plan`)→ 手動承認(SNS 通知)→ Deploy(`terraform-apply`)の 4 ステージで作成する

buildspec 内の `TF_DIR` はリポジトリルートからの相対パス(`projects/06-iac-cicd/handson/environments/dev`)になっています。リポジトリ構成を変えた場合は書き換えてください。また、CodeBuild 上では `terraform.tfvars` が存在しないため、`my_ip_cidr` は CodeBuild プロジェクトの環境変数 `TF_VAR_my_ip_cidr` として渡してください。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| `Error: Failed to get existing workspaces` / `NoSuchBucket` | `backend.tf` の `bucket` がステップ1で作ったバケット名と一致しているか確認する |
| `Error acquiring the state lock` | 別の apply が実行中でないか確認し、誰も実行していなければ `terraform force-unlock <LOCK_ID>` |
| `curl` が応答しない | user_data の完了を 1〜2 分待つ。SG の 80 番が `0.0.0.0/0` で開いているか、EC2 がパブリックサブネットにあるかを確認する |
| SSH できない | `my_ip_cidr` が現在の自分のグローバル IP か再確認する。`key_name` を指定していない場合は SSH ではなく EC2 Instance Connect / SSM Session Manager を検討する |
| `BucketAlreadyExists` | バケット名がグローバルで重複している。名前を変えて再実行する |

## 関連ドキュメント

- [レベル6 本編(設計と解説)](../README.md)
- [レベル2: EC2 Web サーバー(手作業版)](../../02-ec2-web-server/README.md)
- [コスト管理ガイド](../../../docs/03-cost-management.md)
