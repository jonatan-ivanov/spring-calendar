# Prerequisits:
#   - Create a key pair named spring-calendar
# After apply:
#   - Populate secrets (GH creds and keystore pass) in /opt/spring-calendar/application-aws.properties
#   - Copy spring-calendar.p12 into /opt/spring-calendar/spring-calendar.p12
#   - chmod 440 spring-calendar.p12
#   - chown spring-calendar spring-calendar.p12
#   - service spring-calendar restart

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }
  backend "s3" {
    bucket = "vmw-jivanov-tf-state"
    key    = "us-west-2/spring-calendar"
    region = "us-west-2"
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_instance" "spring-calendar" {
  ami                    = "ami-00f7e5c52c0f43726"
  instance_type          = "t2.micro"
  user_data              = file("init-script.sh")
  vpc_security_group_ids = [aws_security_group.spring-calendar.id]
  key_name               = "spring-calendar"

  tags = {
    Name = "spring-calendar"
  }
}

resource "aws_eip" "spring-calendar" {
  instance = aws_instance.spring-calendar.id
  vpc      = true
}

resource "aws_security_group" "spring-calendar" {
  name = "spring-calendar-sg"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "spring-calendar-public-ip" {
  value = aws_eip.spring-calendar.public_ip
}

output "spring-calendar-public-dns" {
  value = aws_eip.spring-calendar.public_dns
}
