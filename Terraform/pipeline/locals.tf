locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  name_prefix = var.project_name

  codebuild_project_name = "${local.name_prefix}-build"
  codepipeline_name      = "${local.name_prefix}-pipeline"
  artifact_bucket_name   = "${local.name_prefix}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"

  source_output_artifact = "source_output"
  build_output_artifact  = "build_output"
}