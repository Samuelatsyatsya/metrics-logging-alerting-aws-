output "vpc_id" {
  description = "Effective VPC ID used by ALB and ECS networking"
  value       = local.effective_vpc_id
}

output "subnet_ids" {
  description = "Effective subnet IDs used by ALB and ECS service networking"
  value       = local.effective_subnet_ids
}

output "frontend_target_group_arn" {
  description = "Target group ARN for frontend service"
  value       = aws_lb_target_group.frontend.arn
}

output "ecs_service_security_group_id" {
  description = "Security group ID to attach to ECS service tasks"
  value       = aws_security_group.ecs_service.id
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the application load balancer"
  value       = aws_lb.main.arn
}
