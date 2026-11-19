output "sample_app_1_public_ip" {
  description = "The public IP of the sample-app-1 instance"
  value       = module.sample_app_1.public_ips
}

output "sample_app_1_instance_id" {
  description = "The ID of the sample-app-1 instance"
  value       = module.sample_app_1.instance_ids
}