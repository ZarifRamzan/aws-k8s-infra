#!/usr/bin/env bash
# ==============================================================================
# validate_credentials.sh - Checks AWS auth before running Terraform
# ==============================================================================
set -e

# Load .env if exists
if [ -f "../.env" ]; then
  set -a && source ../.env && set +a
  echo "✅ Loaded .env variables"
fi

# Check required vars
for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION; do
  if [ -z "${!var}" ]; then
    echo "❌ Missing $var in environment"
    exit 1
  fi
done

# Test AWS CLI
echo "🔍 Testing AWS credentials..."
if aws sts get-caller-identity --region "$AWS_DEFAULT_REGION" &> /dev/null; then
  echo "✅ AWS authentication successful!"
  aws sts get-caller-identity --region "$AWS_DEFAULT_REGION"
else
  echo "❌ AWS authentication failed. Check your keys in .env"
  echo "💡 Tip: Generate new keys at https://console.aws.amazon.com/iam/"
  exit 1
fi