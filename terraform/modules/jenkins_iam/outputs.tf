output "policy_arn" {
  description = "ARN of the Jenkins ECS deployment IAM policy"
  value       = aws_iam_policy.jenkins_ecs_deploy.arn
}
