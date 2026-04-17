resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = local.artifact_bucket_name

  tags = merge(local.common_tags, {
    Name = local.artifact_bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts_pab" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts_encryption" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.name_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-codepipeline-role"
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ArtifactsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.pipeline_artifacts.arn
      },
      {
        Sid    = "S3ArtifactsObjectsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.pipeline_artifacts.arn}/*"
      },
      {
        Sid    = "UseCodeConnections"
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection",
          "codeconnections:UseConnection"
        ]
        Resource = var.codestar_connection_arn
      },
      {
        Sid    = "StartAndReadCodeBuild"
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.app_build.arn
      },
      {
        Sid    = "ECSDeployAccess"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:ListTaskDefinitions",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:TagResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassTaskRolesToECS"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          data.terraform_remote_state.deployment.outputs.ecs_task_execution_role_arn,
          data.terraform_remote_state.deployment.outputs.ecs_task_role_arn
        ]
      }
    ]
  })
}

resource "aws_codepipeline" "app_pipeline" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = [local.source_output_artifact]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Docker_Build_And_Push"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = [local.source_output_artifact]
      output_artifacts = [local.build_output_artifact]

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy_To_ECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = [local.build_output_artifact]

      configuration = {
        ClusterName = data.terraform_remote_state.deployment.outputs.ecs_cluster_name
        ServiceName = data.terraform_remote_state.deployment.outputs.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = local.codepipeline_name
  })
}