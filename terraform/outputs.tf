output "ecs_cluster_name" {
  description = "ECS cluster name used for application deployment"
  value       = try(module.ecs[0].cluster_name, null)
}

output "ecs_service_name" {
  description = "ECS service name used for application deployment"
  value       = try(module.ecs[0].service_name, null)
}

output "ecs_task_definition_family" {
  description = "ECS task definition family"
  value       = try(module.ecs[0].task_definition_family, null)
}

output "rds_endpoint" {
  description = "RDS endpoint used by backend service"
  value       = try(module.rds[0].endpoint, null)
}

output "rds_credentials_secret_arn" {
  description = "Secrets Manager ARN used by ECS backend for DB password"
  value       = try(module.rds[0].credentials_secret_arn, null)
}

output "ecs_alb_dns_name" {
  description = "ECS ALB DNS name"
  value       = try(module.network[0].alb_dns_name, null)
}

output "app_healthcheck_url" {
  description = "Health check URL for Jenkins APP_HEALTHCHECK_URL"
  value       = try("http://${module.network[0].alb_dns_name}${var.ecs_health_check_path}", null)
}

output "jenkins_ecs_deploy_policy_arn" {
  description = "IAM policy ARN attached to Jenkins principal for ECS deploy operations"
  value       = try(module.jenkins_iam[0].policy_arn, null)
}

output "codedeploy_application_name" {
  description = "CodeDeploy application name for ECS blue/green deployments"
  value       = try(module.codedeploy[0].application_name, null)
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name for ECS blue/green deployments"
  value       = try(module.codedeploy[0].deployment_group_name, null)
}
