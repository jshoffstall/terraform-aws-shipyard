provider "aws" {
  profile    = "default"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "shipyard_server" {
  ami                         = "${var.ami_id}"
  instance_type               = "${var.instance_type}" 
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = [aws_security_group.allow_http_docs_site.id]
  associate_public_ip_address = true
  tags                        = {
    Name = "${var.lab_name}"
  } 
  user_data                   = <<EOF
    #! /bin/bash
    sudo curl https://shipyard.run/install | bash
    shipyard run ${var.blueprint_repo}
  EOF
}

output "public_instance_ip_addr" {
  value = aws_instance.shipyard_server.public_ip
}

output "private_instance_ip_addr" {
  value = aws_instance.shipyard_server.private_ip
}

resource "aws_security_group" "allow_http_docs_site" {
  name        = "allow_http_docs_site"
  description = "Allow http over 18080"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from WAN"
    from_port   = 18080
    to_port     = 18080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from WAN"
    from_port   = 22 
    to_port     = 22 
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

