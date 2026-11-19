
# AWS Configuration
variable "aws_region" {
  description = "AWS Region for infrastructure deployment"
  type        = string
  default     = "ap-southeast-2"
}

# Project Configuration
variable "project_name" {
  description = "Project name used to identify AWS infrastructure resources"
  type        = string
  default     = "sample-app"
}

# AMI Configuration
variable "ami_name" {
  description = "Base AMI name produced by Packer, without the wildcard suffix"
  type        = string
  default     = "sample-app"
}

# Application Configuration
variable "app_http_port" {
  description = "HTTP port used by the Node.js application"
  type        = number
  default     = 8080
}

variable "app_health_check_path" {
  description = "HTTP endpoint used by ALB to check application health"
  type        = string
  default     = "/health"
}

# EC2 Configuration
variable "ec2_instance_type" {
  description = "EC2 instance type used by the Auto Scaling Group"
  type        = string
  default     = "t3.micro"
}

# Auto Scaling Group Configuration
variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 10
}

# Instance Refresh Configuration
variable "min_healthy_percentage" {
  description = "Minimum percentage of healthy ASG capacity during Instance Refresh"
  type        = number
  default     = 100
}

variable "max_healthy_percentage" {
  description = "Maximum percentage of ASG capacity during Instance Refresh"
  type        = number
  default     = 200
}

variable "auto_rollback" {
  description = "Automatically roll back an Instance Refresh if it fails"
  type        = bool
  default     = true
}
variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
  default     = 3
}
