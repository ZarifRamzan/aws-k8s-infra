#!/usr/bin/env bash
# ==============================================================================
# terraform_run.sh - Orchestrates Terraform + Ansible deployment
# ==============================================================================
set -e
cd "$(dirname "$0")"

# Load .env if exists
if [[ -f "../.env" ]]; then
  set -a && source ../.env && set +a
  echo "✅ Loaded AWS credentials from .env"
fi

# Ensure jq is installed for JSON parsing
if ! command -v jq &> /dev/null; then
  echo "⚠️  Installing 'jq' for output parsing..."
  sudo apt-get update && sudo apt-get install -y jq
fi

# ==============================================================================
# Terraform Installation & Update Functions
# ==============================================================================

install_terraform() {
    # Check if terraform exists in PATH
    if command -v terraform &>/dev/null; then
        # Extract version (handles both JSON & plain text output)
        CURRENT=$(terraform version 2>/dev/null | head -n1 | awk '{print $2}' | tr -d 'v')
        echo "✅ Terraform found: v${CURRENT}"
        echo "🔄 Proceeding to version check..."
    else
        echo "❌ Terraform not found. Installing latest version..."
    fi
    
    # Always delegate to version-check/update logic
    install_latest
}

install_latest() {
    # 1️ Fetch latest version from HashiCorp GitHub releases
    LATEST_VER=$(curl -s "https://api.github.com/repos/hashicorp/terraform/releases/latest" \
                 | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')

    if [[ -z "$LATEST_VER" ]]; then
        echo "❌ Failed to fetch latest version. Check internet connection or GitHub API."
        return 1
    fi

    # 2️⃣ Get currently installed version (if any)
    CURRENT_VER=""
    if command -v terraform &>/dev/null; then
        CURRENT_VER=$(terraform version 2>/dev/null | head -n1 | awk '{print $2}' | tr -d 'v')
    fi

    # 3️⃣ Compare versions
    if [[ "$CURRENT_VER" == "$LATEST_VER" ]]; then
        echo "✅ Terraform is already up-to-date (v${LATEST_VER})"
        return 0
    fi

    echo "📥 Installing/Updating: v${CURRENT_VER:-none} → v${LATEST_VER}"

    # 4️⃣ Download & Install
    TMP_DIR=$(mktemp -d)
    DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${LATEST_VER}/terraform_${LATEST_VER}_linux_amd64.zip"

    # Download binary
    curl -fsSL "$DOWNLOAD_URL" -o "${TMP_DIR}/terraform.zip" || { 
        echo "❌ Download failed"; rm -rf "$TMP_DIR"; return 1; 
    }

    # Extract & move to system path
    unzip -qo "${TMP_DIR}/terraform.zip" -d "${TMP_DIR}/"
    sudo mv "${TMP_DIR}/terraform" /usr/local/bin/terraform
    sudo chmod 755 /usr/local/bin/terraform

    # Cleanup temporary files
    rm -rf "$TMP_DIR"

    # 5️⃣ Verify installation
    INSTALLED_VER=$(terraform version 2>/dev/null | head -n1 | awk '{print $2}' | tr -d 'v')
    if [[ "$INSTALLED_VER" == "$LATEST_VER" ]]; then
        echo "✅ Successfully installed/updated to Terraform v${LATEST_VER}"
    else
        echo "️  Version mismatch! Expected v${LATEST_VER}, got v${INSTALLED_VER}"
    fi
}

# ==============================================================================
# Execute Functions
# ==============================================================================
install_terraform

echo "🚀 Initializing Terraform..."
terraform init -input=false -upgrade

echo "📐 Planning infrastructure..."
terraform plan -out=tfplan -input=false

echo "✅ Applying configuration..."
terraform apply -auto-approve tfplan

echo "📦 Extracting outputs for Ansible..."
# Use -json to safely handle lists, maps, and strings
OUTPUTS=$(terraform output -json)

BUILD_IP=$(echo "$OUTPUTS" | jq -r '.build_server_ip.value')
MONITOR_IP=$(echo "$OUTPUTS" | jq -r '.monitoring_server_ip.value')
MASTER_IP=$(echo "$OUTPUTS" | jq -r '.k8s_master_ip.value')
WORKER1_IP=$(echo "$OUTPUTS" | jq -r '.k8s_workers_ips.value[0]')
WORKER2_IP=$(echo "$OUTPUTS" | jq -r '.k8s_workers_ips.value[1]')

# Resolve SSH Key Path (Priority: Env Var > tfvars > Fallback)
if [[ -n "$TF_VAR_ssh_private_key_path" ]]; then
  SSH_KEY="$TF_VAR_ssh_private_key_path"
elif grep -q 'ssh_private_key_path' terraform.tfvars 2>/dev/null; then
  # Extract path from tfvars, handle quotes & expand ~
  SSH_KEY=$(grep 'ssh_private_key_path' terraform.tfvars | sed 's/.*=\s*"\(.*\)"/\1/; s/.*=\s*\(.*\)/\1/' | tr -d '" ')
  SSH_KEY="${SSH_KEY/#\~/$HOME}"
else
  SSH_KEY="$HOME/.ssh/aws5-v5.pem"
fi

# Verify key exists
if [[ ! -f "$SSH_KEY" ]]; then
  echo "❌ SSH Key not found: $SSH_KEY"
  echo "💡 Fix: Set TF_VAR_ssh_private_key_path or update terraform.tfvars"
  exit 1
fi

echo "🔑 Using SSH Key: $SSH_KEY"

# Generate Ansible Inventory
mkdir -p ../ansible
cat > ../ansible/inventory.ini << EOF
[build]
$BUILD_IP

[monitoring]
$MONITOR_IP

[k8s_master]
$MASTER_IP

[k8s_workers]
$WORKER1_IP
$WORKER2_IP

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=$SSH_KEY
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
echo ""
echo "✅ Ansible inventory generated:"
cat ../ansible/inventory.ini
echo ""
echo "🎉 Infrastructure deployment & configuration complete!"