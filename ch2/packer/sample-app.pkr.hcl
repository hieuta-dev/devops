packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.1"
      source  = "github.com/hashicorp/amazon"
    }

    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
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
  region      = "ap-southeast-2"
}

source "amazon-ebs" "aws" {
  ami_name      = "sample-app-${uuidv4()}"
  instance_type = "t3.micro"
  region        = "ap-southeast-2"
  source_ami    = data.amazon-ami.amazon-linux.id
  ssh_username  = "ec2-user"
}

source "docker" "local" {
  image  = "amazonlinux:2023"
  commit = true
}


build {
  sources = [
    "source.amazon-ebs.aws",
    "source.docker.local"
  ]


  provisioner "shell" {
    only = ["amazon-ebs.aws"]

    inline = [
      "sudo mkdir -p /opt/sample-app",
      "sudo chown ec2-user:ec2-user /opt/sample-app"
    ]
  }

  provisioner "shell" {
    only = ["docker.local"]

    inline = [
      "mkdir -p /opt/sample-app"
    ]
  }

  provisioner "file" {
    source      = "app.js"
    destination = "/opt/sample-app/app.js"
  }

  provisioner "shell" {
    script       = "install-node.sh"
    pause_before = "30s"
  }
}