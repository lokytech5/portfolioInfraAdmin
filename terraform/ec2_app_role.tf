// Create EC2 IAM role

resource "aws_iam_role" "portfolio_app" {
  name               = "portfolio-app-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "Portfolio App EC2 Role"
    Environment = "Development"
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

// SSM Read only policy 

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm_app_read" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
      "ssm:List*"
    ]
    resources = ["arn:aws:ssm:${data.aws_caller_identity.current.account_id}:parameter/portfolio/backend/*"]
  }
}

resource "aws_iam_policy" "ssm_app_read" {
  name        = "portfolio-ssm-app-read"
  description = "Allow EC2 app to read SSM parameters Store for /portfolio/backend/*"
  policy      = data.aws_iam_policy_document.ssm_app.read.json
}

#Attach SSM Read Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "app_ssm_attach" {
  role       = aws_iam_role.portfolio_app.name
  policy_arn = aws_iam_policy.ssm_app_read.arn
}

#Creating the instance profile for the EC2 role
resource "aws_iam_instance_profile" "portfolio_app_instance_profile" {
  name = "portfolio-app-instance-profile"
  role = aws_iam_role.portfolio_app.name
}
