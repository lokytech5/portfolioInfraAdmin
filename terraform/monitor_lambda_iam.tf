variable "monitor_lambda_name" {
  description = "Lambda function name"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for EC2 instance activity"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for EC2 notifications"
  type        = string
}

variable "stop_lambda_arn" {
  description = "ARN of Stop Lambda (invoked by Monitor Lambda)"
  type        = string
}

# 1. Trust policy for Lambda
data "aws_iam_policy_document" "monitor_lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 2. Permission policy
data "aws_iam_policy_document" "monitor_lambda_policy" {
  statement {
    sid = "CloudWatchRead"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }

  statement {
    sid = "DynamoDBRW"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:DescribeTable"
    ]
    resources = [var.dynamodb_table_arn]
  }

  statement {
    sid = "SNSPublish"
    actions = [
      "sns:Publish"
    ]
    resources = [var.sns_topic_arn]
  }

  statement {
    sid = "InvokeStopLambda"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [var.stop_lambda_arn]
  }

  # Standard Lambda logging to CloudWatch
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# 3. Role
resource "aws_iam_role" "monitor_lambda" {
  name               = "${var.monitor_lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.monitor_lambda_assume.json
  tags = {
    Name = "${var.monitor_lambda_name}-role"
  }
}

# 4. Policy
resource "aws_iam_policy" "monitor_lambda_policy" {
  name   = "${var.monitor_lambda_name}-policy"
  policy = data.aws_iam_policy_document.monitor_lambda_policy.json
}

# 5. Attach policy to role
resource "aws_iam_role_policy_attachment" "monitor_lambda_attach" {
  role       = aws_iam_role.monitor_lambda.name
  policy_arn = aws_iam_policy.monitor_lambda_policy.arn
}

# 6. Output the role ARN (for use in your main repo)
output "monitor_lambda_role_arn" {
  value = aws_iam_role.monitor_lambda.arn
}

output "monitor_lambda_role_name" {
  value = aws_iam_role.monitor_lambda.name
}
