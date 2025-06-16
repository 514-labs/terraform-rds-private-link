# Create a Lambda function to check the RDS instance IP address
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/514/lambda/${local.lambda_name}"
  retention_in_days = 30
  tags = merge(var.default_tags, {
    Name = "${local.lambda_name}-log-group"
  })
}

resource "aws_lambda_function" "check_rds_ip" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"

  filename = data.archive_file.lambda_zip.output_path

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLUSTER_NAME = var.rds_cluster_details.name
      CLUSTER_PORT = var.rds_cluster_details.port
      TARGET_GROUP_ARN = aws_lb_target_group.rds_cluster_target_group.arn
    }
  }

  logging_config {
    log_format = "JSON"
    log_group = aws_cloudwatch_log_group.lambda_log_group.name
  }

  tags = merge(var.default_tags, {
    Name = "${var.nlb_name}-lambda-function"
  })
}

resource "aws_cloudwatch_event_rule" "rds_ip_check_rule" {
  name                = "${substr(var.nlb_name, 0, 12)}-rds-ip-check-rule"
  description         = "Fires every ${var.schedule_expression} to check the RDS instance IP address"
  schedule_expression = var.schedule_expression

  tags = merge(var.default_tags, {
    Name = "${var.nlb_name}-rds-ip-check-rule"
  })
}

resource "aws_cloudwatch_event_target" "check_rds_ip_event_target" {
  rule      = aws_cloudwatch_event_rule.rds_ip_check_rule.name
  target_id = "${substr(var.nlb_name, 0, 12)}-check-rds-ip"
  arn       = aws_lambda_function.check_rds_ip.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_rds_ip" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_rds_ip.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_ip_check_rule.arn
}
