# bootstrap/main.tf
# tfstate 保存用の S3 バケットと state lock 用の DynamoDB テーブルを作成します。
# このディレクトリ自体はローカル state(terraform.tfstate)で apply する前提です。
# (state 保存先がまだ存在しない段階で実行するため、backend "s3" は指定しません)

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ---------------------------------------------------------------------------
# tfstate 保存用 S3 バケット
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name

  # 学習用途のため、destroy 時にオブジェクトが残っていても削除できるようにしています。
  # 実務では誤削除防止のため false(既定値)にしてください。
  force_destroy = true

  tags = {
    Name = var.tfstate_bucket_name
  }
}

# バージョニング: 誤った apply でも過去の tfstate に戻せるようにする
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# デフォルト暗号化(SSE-S3): tfstate には機密情報が平文で含まれることがある
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスをすべてブロック
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# state lock 用 DynamoDB テーブル
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # オンデマンド(従量課金)
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.lock_table_name
  }
}
