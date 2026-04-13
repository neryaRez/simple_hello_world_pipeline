#!/usr/bin/env bash
set -euo pipefail

TFSTATE_BUCKET_PREFIX="${TFSTATE_BUCKET_PREFIX:-simple-hello-world-tfstate}"
LOCK_TABLE_PREFIX="${LOCK_TABLE_PREFIX:-simple-hello-world-tf-lock}"
AWS_REGION="${AWS_REGION:-us-east-1}"
STATE_KEY="${STATE_KEY:-pipeline/terraform.tfstate}"

aws sts get-caller-identity > /dev/null 2>&1 || {
  echo "❌ AWS CLI not configured. Run aws configure first."
  exit 1
}

ACCOUNT_ID="$(aws sts get-caller-identity --query "Account" --output text)"

TFSTATE_BUCKET="${TFSTATE_BUCKET_PREFIX}-${ACCOUNT_ID}"
LOCK_TABLE="${LOCK_TABLE_PREFIX}-${ACCOUNT_ID}"

echo "✅ AWS region: ${AWS_REGION}"
echo "✅ AWS account: ${ACCOUNT_ID}"
echo "✅ TF state bucket: ${TFSTATE_BUCKET}"
echo "✅ Lock table: ${LOCK_TABLE}"
echo "✅ State key: ${STATE_KEY}"

if ! aws s3api head-bucket --bucket "${TFSTATE_BUCKET}" 2>/dev/null; then
  echo "❌ Backend bucket does not exist: ${TFSTATE_BUCKET}"
  exit 1
fi

if ! aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "❌ DynamoDB lock table does not exist: ${LOCK_TABLE}"
  exit 1
fi

terraform init \
  -backend-config="bucket=${TFSTATE_BUCKET}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=${LOCK_TABLE}"