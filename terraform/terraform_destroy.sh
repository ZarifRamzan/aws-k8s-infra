#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
terraform destroy -auto-approve