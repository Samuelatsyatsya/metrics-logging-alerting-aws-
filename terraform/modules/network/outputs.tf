output "vpc_id" {
  description = "VPC ID used by ALB and ECS networking"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs used by ALB and ECS service networking"
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
}

output "frontend_target_group_arn" {
  description = "Target group ARN for frontend service"
  value       = aws_lb_target_group.frontend.arn
}

output "frontend_target_group_name" {
  description = "Target group name for frontend service"
  value       = aws_lb_target_group.frontend.name
}

output "backend_metrics_target_group_arn" {
  description = "Target group ARN for backend metrics endpoint"
  value       = aws_lb_target_group.backend_metrics.arn
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

output "alb_listener_arn" {
  description = "ARN of the production ALB listener"
  value       = aws_lb_listener.https.arn
}
