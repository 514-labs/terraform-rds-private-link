# Get the state of the RDS cluster using aws_db_cluster
data "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = var.rds_cluster_details.name

  lifecycle {
    postcondition {
      condition     = self.storage_encrypted == true
      error_message = "The RDS cluster must be encrypted."
    }
  }
}

# Get the VPC details using aws_vpc
data "aws_vpc" "rds_vpc" {
  id = var.vpc_id
}

data "aws_db_subnet_group" "rds_cluster_subnet_group" {
  name = data.aws_rds_cluster.rds_cluster.db_subnet_group_name
}

data "aws_subnet" "rds_subnet" {
  for_each = toset(data.aws_db_subnet_group.rds_cluster_subnet_group.subnet_ids)

  id = each.value
}

data "dns_a_record_set" "rds_cluster_writer_ip" {
  host = data.aws_rds_cluster.rds_cluster.endpoint
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

locals {
  subnet_az_ids = [for subnet in data.aws_subnet.rds_subnet : subnet.availability_zone_id]
}
