# modules/vpc/variables.tf

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "パブリックサブネットのCIDRブロック"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "サブネットを配置するアベイラビリティゾーン"
  type        = string
  default     = "ap-northeast-1a"
}

variable "project_name" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = "handson"
}
