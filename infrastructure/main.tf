terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "default" {
  key_name   = "valkey-bench-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "bench" {
  name   = "valkey-bench-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 9001
    to_port         = 9001
    protocol        = "tcp"
    security_groups = [aws_security_group.bench.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_placement_group" "bench" {
  count    = var.use_placement_group ? 1 : 0
  name     = "valkey-bench-pg"
  strategy = var.placement_group_strategy
}

module "server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name    = "valkey-server"
  instance_type = var.server_type
  ami           = data.aws_ami.amzn2.id
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bench.id]
  key_name = aws_key_pair.default.key_name
  placement_group = var.use_placement_group ? aws_placement_group.bench[0].name : null
  user_data = file("${path.module}/user_data/server.sh")
}

module "client" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  name    = "valkey-client"
  instance_type = var.client_type
  ami           = data.aws_ami.amzn2.id
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bench.id]
  key_name = aws_key_pair.default.key_name
  placement_group = var.use_placement_group ? aws_placement_group.bench[0].name : null
  user_data = file("${path.module}/user_data/client.sh")
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
