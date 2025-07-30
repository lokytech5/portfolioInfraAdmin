output "portfolio_app_instance_profile_name" {
  value = aws_iam_instance_profile.portfolio_app_instance_profile.name
}

output "ssm_app_read_policy_json" {
  value = data.aws_iam_policy_document.ssm_app_read.json
}
