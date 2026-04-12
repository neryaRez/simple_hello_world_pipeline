terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "simple-hello-world"
}

variable "bucket_prefix" {
  type    = string
  default = "simple-hello-world-tfstate"
}

variable "lock_table_prefix" {
  type    = string
  default = "simple-hello-world-tf-lock"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tf_bucket" {
  bucket = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "${var.lock_table_prefix}-${data.aws_caller_identity.current.account_id}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_account_public_access_block" "acc_access_tfstate" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bucket_access_tfstate" {
  bucket = aws_s3_bucket.tf_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_tfstate" {
  bucket = aws_s3_bucket.tf_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_tfstate" {
  bucket = aws_s3_bucket.tf_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "tfstate_bucket" {
  value = aws_s3_bucket.tf_bucket.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_lock.name
}

output "aws_region" {
  value = var.aws_region
}