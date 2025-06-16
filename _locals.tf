locals {
  # Target group name following AWS naming conventions
  target_group_name = "${substr(var.rds_cluster_details.name, 0, 12)}-${var.rds_cluster_details.port}-tg"
  
  # Lambda function name
  lambda_name = "${substr(var.nlb_name, 0, 12)}-check-rds-ip"
}
