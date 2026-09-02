# environments/dev/variables.tf

variable "my_ip_cidr" {
  description = "SSH接続を許可する自分のグローバルIP(CIDR形式)"
  type        = string
}

variable "project_name" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = "handson-dev"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH接続に使うEC2キーペア名(不要な場合はnull)"
  type        = string
  default     = null
}
