# Create an IAM policy for the Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_${substr(var.nlb_name, 0, 12)}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json

  tags = merge(var.default_tags, {
    Name = "${var.nlb_name}-lambda-execution-role"
  })
}

# Create an IAM policy for the Lambda function
resource "aws_iam_role_policy" "lambda_execution_role_policy" {
  name   = "${substr(var.nlb_name, 0, 12)}-lambda-execution-role-policy"
  role   = aws_iam_role.lambda_execution_role.id
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

# Define the IAM policy document with specific resource restrictions
data "aws_iam_policy_document" "lambda_execution_policy" {
  # CloudWatch Logs permissions - specific to Lambda's log group
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/514/lambda/${local.lambda_name}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/514/lambda/${local.lambda_name}:*"
    ]
  }

  # RDS permissions - specific to the cluster and its instances
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBClusters"
    ]
    resources = [
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster:${var.rds_cluster_details.name}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = [
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${var.rds_cluster_details.name}-*"
    ]
  }

  # Load balancer describe permissions - these operations require broader access
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTargets"
    ]
    resources = ["*"]
  }

  # Load balancer modify permissions - specific to the target group
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:targetgroup/${local.target_group_name}/*"
    ]
  }
}