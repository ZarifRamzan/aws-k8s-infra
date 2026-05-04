#!/usr/bin/env bash
# ==============================================================================
# terraform_destroy.sh - Safely destroys Terraform-managed infrastructure
# ==============================================================================
set -e
cd "$(dirname "$0")"

source ../.env 2>/dev/null || true

echo "🗑️  Destroying Terraform infrastructure..."
terraform destroy -auto-approve

echo " Cleaning up temporary artifacts..."
rm -rf .terraform/
rm -f terraform.tfstate*
rm -f *.tfplan        # ✅ Remove stale plan files
rm -f tfplan          # ✅ Remove default plan file if present

# Clean up dynamically generated Ansible inventory
echo "🗑️  Removing stale Ansible inventory..."
rm -f ../ansible/inventory.ini

# ⚠️  NOTE: .terraform.lock.hcl is PRESERVED intentionally
# It ensures provider version consistency across machines & re-deploys.

echo "✅ Terraform destroyed & state cleared. Ready for new 'apply'."