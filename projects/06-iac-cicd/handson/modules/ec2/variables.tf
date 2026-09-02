# modules/ec2/variables.tf

variable "subnet_id" {
  description = "EC2を配置するサブネットのID"
  type        = string
}

variable "security_group_ids" {
  description = "EC2にアタッチするセキュリティグループIDのリスト"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH接続に使うEC2キーペア名(不要な場合はnullのまま)"
  type        = string
  default     = null
}

variable "project_name" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = "handson"
}
