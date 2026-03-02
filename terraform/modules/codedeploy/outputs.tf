output "application_name" {
  description = "CodeDeploy application name for ECS deployments"
  value       = aws_codedeploy_app.ecs.name
}

output "deployment_group_name" {
  description = "CodeDeploy deployment group name (null when not created)"
  value       = try(aws_codedeploy_deployment_group.ecs[0].deployment_group_name, null)
}

output "service_role_arn" {
  description = "IAM role ARN used by CodeDeploy for ECS deployments"
  value       = aws_iam_role.codedeploy.arn
}

output "green_target_group_arn" {
  description = "Green target group ARN used by CodeDeploy blue/green deployments"
  value       = try(aws_lb_target_group.green[0].arn, null)
}
