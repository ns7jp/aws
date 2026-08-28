variable "aws_region" {
  description = "AWS Region used for this case pack."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Short name used in resources and tags."
  type        = string
  default     = "aws-casepack"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 3-21 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "lab uses one NAT gateway; production uses one per AZ."
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["lab", "production"], var.environment)
    error_message = "environment must be lab or production."
  }
}

variable "owner" {
  description = "Owner tag used for cost allocation and operations."
  type        = string
  default     = "portfolio-learner"
}

variable "vpc_cidr" {
  description = "CIDR of the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs, one for each AZ."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs, one for each AZ."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Normal number of EC2 instances."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 2 && var.desired_capacity <= 4
    error_message = "desired_capacity must be between 2 and 4."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
  default     = 14
}

variable "alarm_sns_topic_arn" {
  description = "Optional pre-created SNS topic ARN for tested alarm notifications."
  type        = string
  default     = ""
}
