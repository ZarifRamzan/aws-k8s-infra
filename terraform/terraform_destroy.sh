#!/usr/bin/env bash

# Stops immediately if terraform destroy fails
set -e
# Critical: Ensures Terraform runs in the correct directory where terraform.tfstate and configs live
cd "$(dirname "$0")"
# Critical: Skips the interactive yes/no prompt so the script doesn't hang
terraform destroy -auto-approve