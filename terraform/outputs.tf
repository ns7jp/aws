output "account_id" {
  description = "AWS account ID. Treat as sensitive in public evidence."
  value       = data.aws_caller_identity.current.account_id
  sensitive   = true
}

output "aws_region" {
  description = "Deployment Region."
  value       = var.aws_region
}

output "availability_zones" {
  description = "Availability Zones used by the subnets."
  value       = local.azs
}

output "alb_url" {
  description = "Learning demo URL. Add HTTPS before production use."
  value       = "http://${aws_lb.web.dns_name}"
}

output "autoscaling_group_name" {
  description = "ASG name used by verification commands."
  value       = aws_autoscaling_group.web.name
}

output "target_group_arn" {
  description = "Target group ARN used by health verification."
  value       = aws_lb_target_group.web.arn
}

output "private_subnet_ids" {
  description = "Private subnet IDs hosting the web instances."
  value       = aws_subnet.private[*].id
}

output "web_security_group_id" {
  description = "Security group attached to web instances."
  value       = aws_security_group.web.id
}

output "estimated_nat_gateway_count" {
  description = "NAT gateway count: lab=1 and production=2."
  value       = local.nat_count
}

output "alarm_notifications_configured" {
  description = "True only when a pre-created SNS topic ARN was supplied."
  value       = var.alarm_sns_topic_arn != ""
}
