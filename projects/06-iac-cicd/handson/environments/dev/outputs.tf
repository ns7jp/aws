# environments/dev/outputs.tf

output "web_server_public_ip" {
  description = "作成したEC2のパブリックIP"
  value       = module.ec2.public_ip
}

output "web_server_instance_id" {
  description = "作成したEC2インスタンスのID"
  value       = module.ec2.instance_id
}

output "vpc_id" {
  description = "作成したVPCのID"
  value       = module.vpc.vpc_id
}
