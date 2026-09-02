# modules/ec2/outputs.tf

output "instance_id" {
  description = "作成したEC2インスタンスのID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "EC2に割り当てられたパブリックIP(Elastic IP)"
  value       = aws_eip.web.public_ip
}
