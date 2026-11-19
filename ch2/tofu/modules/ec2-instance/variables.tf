variable "name" {
  description = "The name for the EC2 instance and all resources."
  type        = string
}

variable "number_of_instances_EC2"{
    description = "Number of instances EC2 should be created"
    type = number
}