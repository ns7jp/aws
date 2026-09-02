# modules/ec2/main.tf
# Amazon Linux 2023 上に Apache(httpd)を起動する Web サーバーを作成し、Elastic IP を割り当てます。

# 最新の Amazon Linux 2023 AMI ID を SSM パラメータストア(AWS 公開パラメータ)から取得
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd
              systemctl enable --now httpd
              echo "<h1>Hello from Terraform-managed EC2</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-web-server"
  }
}

# 固定のパブリック IP(Elastic IP)
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-web-eip"
  }
}
