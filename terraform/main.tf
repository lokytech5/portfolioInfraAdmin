terraform {
  backend "s3" {
    bucket         = "portfolioinfra-admin-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "portfolioInfra-Admin-Lock"
  }
}

resource "aws_iam_user" "infra_developer" {
  name = "infra-developer"
  tags = {
    Role        = "Infrastructure Developer"
    Environment = "Development"
  }

}

resource "aws_iam_group" "infra_developers" {
  name = "infra-developers"
}

resource "aws_iam_user_group_membership" "infra_developer_membership" {
  user   = aws_iam_user.infra_developer.name
  groups = [aws_iam_group.infra_developers.name]
}

#Create a policy that allows typical Terraform infra actions
resource "aws_iam_policy" "infra_developer_policy" {
  name        = "infra-developer-policy"
  description = "Allow infra developer to manage resources via Terraform"
  policy      = data.aws_iam_policy_document.infra_developer_policy.json
}

data "aws_iam_policy_document" "infra_developer_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "s3:*",
      "dynamodb:*",
      "iam:List*",
      "iam:Get*",
      "iam:CreateRole",
      "iam:PassRole",
      "cloudwatch:*",
      "logs:*",
      "autoscaling:*",
      "ssm:*",

    ]
    resources = ["*"]
  }
}

resource "aws_iam_group_policy_attachment" "infra_developers_attach" {
  group      = aws_iam_group.infra_developers.name
  policy_arn = aws_iam_policy.infra_developer_policy.arn
}
