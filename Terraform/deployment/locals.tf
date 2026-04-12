locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  name_prefix = var.project_name

  ecr_repository_name = "${local.name_prefix}-repo"
  ecs_cluster_name    = "${local.name_prefix}-cluster"
  ecs_service_name    = "${local.name_prefix}-service"
  task_family         = "${local.name_prefix}-task"

  alb_name          = "${local.name_prefix}-alb"
  target_group_name = "${local.name_prefix}-tg"

  log_group_name = "/ecs/${var.project_name}"
}