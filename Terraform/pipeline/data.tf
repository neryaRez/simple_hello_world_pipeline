data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "terraform_remote_state" "deployment" {
  backend = "s3"

  config = {
    bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
    key    = var.deployment_state_key
    region = var.aws_region
  }
}