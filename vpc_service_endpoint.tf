# Create VPC endpoint service for the Load Balancer
resource "aws_vpc_endpoint_service" "rds_lb_endpoint_service" {
  acceptance_required        = var.acceptance_required
  network_load_balancer_arns = [aws_lb.rds_lb.arn]

  supported_regions = var.supported_regions
  allowed_principals = var.allowed_principals

  tags = merge(var.default_tags, {
    Name = "${var.nlb_name}-endpoint-service"
  })
}