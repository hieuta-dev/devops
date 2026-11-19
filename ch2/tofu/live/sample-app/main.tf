
provider "aws" {                                               
  region = "ap-southeast-2"
}

module "sample_app_1" {
   source = "github.com/brikis98/devops-book//ch2/tofu/modules/ec2-instance?ref=1.0.0"

  name = "sample-app-tofu-1"
  number_of_instances_EC2 = 3
}