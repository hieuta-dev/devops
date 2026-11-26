provider "aws" {
  region = "ap-southeast-2"
}

module "cluster" {
  source  = "../../modules/eks-cluster"

  name        = "eks-sample"        
  eks_version = "1.33"              

  instance_type        = "t3.small" 
  min_worker_nodes     = 3          
  max_worker_nodes     = 10    
  enable_aws_load_balancer_controller = true 
     
}