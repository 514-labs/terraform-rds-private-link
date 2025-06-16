module "fiveonefour_private_link" {
  source  = "git::git@github.com:514-labs/terraform-rds-private-link.git?ref=MOOSE-1518-terraform-aws-rds-private-link-initial-setup"

  ### Name of the NLB
  ### this name is used to name most other resources
  nlb_name             = "514-private-link"

  ### VPC ID of the VPC that the RDS cluster is in
  vpc_id               = "vpc-123456789012"

  ### RDS cluster details that will be used to create the PrivateLink endpoint
  rds_cluster_details = {
      name = "jw-aurora-postgres"
      port = 5432
  }

  acceptance_required = true
  ### This is the ARN for the Boreal Account
  allowed_principals  = ["arn:aws:iam::620936554363:root"]
  ### Supported regions for the PrivateLink endpoint. must include us-east-2 for connection to Boreal
  supported_regions   = ["us-east-2"]

  default_tags = {
    Purpose = "514-private-link"
  }
}