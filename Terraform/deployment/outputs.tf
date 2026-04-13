output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for pushing the application image"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app_cluster.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app_service.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group used by the ECS task"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}