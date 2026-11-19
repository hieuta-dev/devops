
provider "aws" {
  region = var.aws_region
}

module "asg" {
  source = "../../modules/asg"

  name              = "${var.project_name}-asg"
  ami_name          = "${var.ami_name}-*"
  user_data         = filebase64("${path.module}/user-data.sh")
  app_http_port     = var.app_http_port
  instance_type     = var.ec2_instance_type

  min_size          = var.asg_min_size
  max_size          = var.asg_max_size

  alb_id            = module.alb.alb_id
  target_group_arns = [module.alb.target_group_arn]

  instance_refresh = {
    min_healthy_percentage = var.min_healthy_percentage
    max_healthy_percentage = var.max_healthy_percentage
    auto_rollback          = var.auto_rollback
    desired_capacity       = var.asg_desired_capacity 
  }
}

module "alb" {
  source = "../../modules/alb"

  name                  = "${var.project_name}-alb"
  app_health_check_path = var.app_health_check_path
  app_http_port         = var.app_http_port
}
