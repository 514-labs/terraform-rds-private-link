# Return the aws_vpc_endpoint_service resource for the RDS endpoint service including the service name and ID
output "rds_endpoint_service" {
  description = "The aws_vpc_endpoint_service resource for the RDS endpoint service including the service name and ID"
  value       = aws_vpc_endpoint_service.rds_lb_endpoint_service
}

output "vpc_service_endpoint_name" {
  description = "The name of the VPC service endpoint"
  value       = aws_vpc_endpoint_service.rds_lb_endpoint_service.service_name
}

output "vpc_service_endpoint_az_ids" {
  description = "The AZ IDs for the VPC service endpoint"
  value       = local.subnet_az_ids
}