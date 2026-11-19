variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "ami_version" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "ami_tags" {
  type    = map(string)
  default = {}
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "project_name" {
  type    = string
  default = "sample-app"
}