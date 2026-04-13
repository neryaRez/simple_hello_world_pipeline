output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.app_build.name
}

output "codepipeline_name" {
  description = "CodePipeline pipeline name"
  value       = aws_codepipeline.app_pipeline.name
}

output "pipeline_artifact_bucket_name" {
  description = "S3 bucket used for pipeline artifacts"
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}

output "deployment_ecr_repository_url" {
  description = "ECR repository URL read from deployment remote state"
  value       = data.terraform_remote_state.deployment.outputs.ecr_repository_url
}

output "deployment_ecs_cluster_name" {
  description = "ECS cluster name read from deployment remote state"
  value       = data.terraform_remote_state.deployment.outputs.ecs_cluster_name
}

output "deployment_ecs_service_name" {
  description = "ECS service name read from deployment remote state"
  value       = data.terraform_remote_state.deployment.outputs.ecs_service_name
}