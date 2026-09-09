# environments/stg/backend.tf
# tfstate の保存先(bootstrap/ で作成した S3 バケット + DynamoDB テーブル)
# bucket は bootstrap の output "tfstate_bucket_name" の値に書き換えてください。
# ※ backend ブロックでは変数(var.*)が使えないため、値を直接記述します。
# ※ key を dev と変えることで、同じバケット・同じロックテーブルを使い回しながら
#    tfstateファイル自体は環境ごとに完全に分離しています(dev/apply が stg に影響することはありません)。

terraform {
  backend "s3" {
    bucket         = "handson-tfstate-<自分のアカウント固有の文字列>"
    key            = "stg/terraform.tfstate" # devとは異なるkeyにして状態ファイルを分離する
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
