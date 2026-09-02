# bootstrap/outputs.tf
# ここで出力される値を environments/dev/backend.tf に転記します。

output "tfstate_bucket_name" {
  description = "tfstate 保存用 S3 バケット名(backend.tf の bucket に指定する)"
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table_name" {
  description = "state lock 用 DynamoDB テーブル名(backend.tf の dynamodb_table に指定する)"
  value       = aws_dynamodb_table.tfstate_lock.name
}
