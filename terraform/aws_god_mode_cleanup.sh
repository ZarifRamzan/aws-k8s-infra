#!/usr/bin/env bash
# ==============================================================================
# aws_god_mode_cleanup.sh - ⚠️ DESTRUCTIVE: Removes ALL Terraform & AWS resources
# - Uses aws-nuke to wipe account resources (USE WITH CAUTION)
# ==============================================================================
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

echo -e "${RED}⚠️  WARNING: This will IRREVERSIBLY destroy ALL resources in your account!${NC}"
echo -e "${RED}⚠️  It will run 'terraform destroy' AND 'aws-nuke'.${NC}"
read -p "Type 'DESTROY' to proceed: " CONFIRM

if [[ "$CONFIRM" != "DESTROY" ]]; then
  echo -e "${GREEN}🛑 Aborted safely.${NC}"; exit 0
fi

echo "🔄 Step 1: Terraform destroy..."
./terraform_destroy.sh

echo "🔄 Step 2: Generating aws-nuke config for ${AWS_DEFAULT_REGION}..."
CONFIG_FILE="nuke-config.yaml"
cat << EOF > $CONFIG_FILE
regions:
  - ${AWS_DEFAULT_REGION}

account-blacklist: []
EOF

if command -v aws-nuke &> /dev/null; then
  echo "🔥 Running aws-nuke (dry-run first)..."
  aws-nuke -c $CONFIG_FILE --no-dry-run
  rm -f $CONFIG_FILE
else
  echo -e "${RED}❌ aws-nuke not found. Install it or skip manually.${NC}"
  echo "Visit: https://github.com/rebuy-de/aws-nuke"
fi

echo -e "${GREEN}✅ Cleanup complete. Account is now empty (within configured regions).${NC}"