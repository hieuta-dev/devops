provider "aws" {
  region = "ap-southeast-2"
}

module "repo" {
  source  = "../../modules/ecr"
  name = "test-k8s"
}