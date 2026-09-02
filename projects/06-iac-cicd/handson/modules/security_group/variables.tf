# modules/security_group/variables.tf

variable "vpc_id" {
  description = "セキュリティグループを作成するVPCのID"
  type        = string
}

variable "my_ip_cidr" {
  description = "SSH接続を許可する自分のグローバルIP(CIDR形式。例: 203.0.113.10/32)"
  type        = string
}

variable "project_name" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = "handson"
}
