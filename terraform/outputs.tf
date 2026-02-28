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

output "ecs_alb_dns_name" {
  description = "ECS ALB DNS name"
  value       = try(module.network[0].alb_dns_name, null)
}

output "app_healthcheck_url" {
  description = "Health check URL for Jenkins APP_HEALTHCHECK_URL"
  value       = try("https://${module.network[0].alb_dns_name}${var.ecs_health_check_path}", null)
}
