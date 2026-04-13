variable "aws_region" {
  description = "AWS region for the pipeline stack"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project base name"
  type        = string
  default     = "simple-hello-world"
}

variable "github_owner" {
  description = "GitHub owner or organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "AWS CodeConnections connection ARN for GitHub"
  type        = string
}

variable "container_name" {
  description = "Container name used by ECS and imagedefinitions.json"
  type        = string
  default     = "hello-world"
}

variable "buildspec_path" {
  description = "Path to buildspec file inside the repository"
  type        = string
  default     = "buildspec.yml"
}

variable "deployment_state_key" {
  description = "S3 backend key of the deployment stack state"
  type        = string
  default     = "deployment/terraform.tfstate"
}