# environments/dev/backend.tf
# tfstate の保存先(bootstrap/ で作成した S3 バケット + DynamoDB テーブル)
# bucket は bootstrap の output "tfstate_bucket_name" の値に書き換えてください。
# ※ backend ブロックでは変数(var.*)が使えないため、値を直接記述します。

terraform {
  backend "s3" {
    bucket         = "handson-tfstate-<自分のアカウント固有の文字列>"
    key            = "dev/terraform.tfstate" # 環境ごとにkeyを変えて分離する
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
