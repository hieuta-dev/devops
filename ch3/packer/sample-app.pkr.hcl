packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "amazon-linux" {
  filters = {
    name                = "al2023-ami-2023.*-x86_64"
    architecture        = "x86_64"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }

  owners      = ["amazon"]
  most_recent = true
  region      = var.aws_region
}

source "amazon-ebs" "aws" {
  ami_name      = "${var.project_name}-${var.ami_version}-${uuidv4()}"
  instance_type = var.ec2_instance_type
  region        = var.aws_region
  source_ami    = data.amazon-ami.amazon-linux.id
  ssh_username  = "ec2-user"

  tags = merge(
    var.ami_tags,
    {
      Name        = var.project_name
      Version     = var.ami_version
      Environment = var.environment
      ManagedBy   = "Packer"
    }
  )
}


build {
  sources = [
    "source.amazon-ebs.aws"
  ]

  provisioner "file" {
    source      = "sample-app"
    destination = "/tmp/"
  }

  provisioner "shell" {
    script       = "install-node.sh"
    pause_before = "30s"
  }
}