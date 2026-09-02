# bootstrap/variables.tf

variable "region" {
  description = "リソースを作成する AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "tfstate_bucket_name" {
  description = "tfstate 保存用 S3 バケット名(グローバルで一意にする。例: handson-tfstate-<自分のアカウント固有の文字列>)"
  type        = string
}

variable "lock_table_name" {
  description = "state lock 用 DynamoDB テーブル名"
  type        = string
  default     = "terraform-state-lock"
}
