# modules/vpc/outputs.tf

output "vpc_id" {
  description = "作成したVPCのID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "作成したパブリックサブネットのID"
  value       = aws_subnet.public.id
}
