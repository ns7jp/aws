# modules/security_group/outputs.tf

output "web_sg_id" {
  description = "作成したWeb用セキュリティグループのID"
  value       = aws_security_group.web.id
}
