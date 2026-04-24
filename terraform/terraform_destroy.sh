#!/bin/bash
set -e

# Clear the screen
clear

echo "-------------------------------------------------------"
echo "🗑️  AWS INFRASTRUCTURE DESTROYER & DEEP CLEANER"
echo "-------------------------------------------------------"

# 1. ENTER TERRAFORM DIRECTORY
echo "🔹 Step 1: Entering Terraform folder..."
TARGET_DIR="/home/zarif/aws-k8s-infra/terraform"

if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR"
else
    echo "❌ Error: Directory $TARGET_DIR not found!"
    exit 1
fi

# 2. DESTROY RESOURCES
echo "🔹 Step 2: Destroying all AWS resources..."
echo "⚠️  Starting destruction in 5 seconds... Press CTRL+C to cancel."
sleep 5

# Initialize to ensure connectivity, then destroy
terraform init -reconfigure > /dev/null
terraform destroy -auto-approve

# 3. DEEP CLEAN (Remove temp and state files)
echo "🔹 Step 3: Removing temporary and unwanted files..."

# List of files/folders to wipe
rm -rf .terraform/                # Local cache of providers/modules
rm -f .terraform.lock.hcl         # Lock file for provider versions
rm -f terraform.tfstate           # The 'memory' of what was built
rm -f terraform.tfstate.backup    # The backup memory
rm -f *.tfstate.lock.info         # Any stuck lock files
rm -f terraform.log               # Any log files if generated

# Delete key-pair
sudo rm -f "/home/zarif/.ssh/aws7" "/home/zarif/.ssh/aws7.pub"

echo "✅ Local Terraform environment is now clean."

echo "-------------------------------------------------------"
echo "🎉 ALL GONE! Infrastructure deleted and files cleaned."
echo "-------------------------------------------------------"