#!/bin/bash
set -e

clear
echo "-------------------------------------------------------"
echo "🚀 AWS & TERRAFORM ULTIMATE SCRIPT"
# Detect real user to avoid path errors
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
echo "👤 User detected: $REAL_USER"
echo "🏠 Working directory: $REAL_HOME"
echo "-------------------------------------------------------"

# 0. Install Terraform
install_terraform() {

    # Check if terraform is installed
    if command -v terraform &> /dev/null; then
        # Extract version number cleanly without using deprecated -short flag
        TF_VERSION=$(terraform version | head -n 1 | grep -oE 'v[0-9.]+')
        echo -e "✅ Terraform is already installed: ${GREEN}$TF_VERSION${NC}"
    else
        echo -e "🟡 Terraform not found. Installing..."
        
        sudo apt-get update -qq && sudo apt-get install -y gnupg software-properties-common curl -qq
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        
        sudo apt-get update -qq && sudo apt-get install terraform -y -qq
        echo -e "✨ ${GREEN}Terraform installation complete!${NC}"
    fi
}

# --- Execution ---
# You can now call the function directly
install_terraform

# 0. Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "🔹 Installing AWS CLI V2..."
    sudo apt-get update -y && sudo apt-get install unzip curl -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip ./aws
fi

# 1. AWS Config
echo "🔹 Step 1: AWS Configuration"
aws configure

# 2. Key-Pair Setup
echo ""
read -p "🔑 Masukkan nama Key-Pair (Default: my-key): " KEY_NAME
KEY_NAME=${KEY_NAME:-"my-key"}

# 3. Generate Key (Target folder zarif, bukan root)
echo "🔹 Step 2: Generating Keypair..."
mkdir -p "$REAL_HOME/.ssh"
rm -f "$REAL_HOME/.ssh/$KEY_NAME" "$REAL_HOME/.ssh/$KEY_NAME.pub"
ssh-keygen -t rsa -b 4096 -f "$REAL_HOME/.ssh/$KEY_NAME" -N ""

# Fix Ownership & Permission (Supaya Ansible tak marah)
sudo chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.ssh/$KEY_NAME"
chmod 600 "$REAL_HOME/.ssh/$KEY_NAME"
echo "✅ Key siap di: $REAL_HOME/.ssh/$KEY_NAME"

# Configure terraform.tfvars
# Gunakan double quotes supaya shell boleh "expand" variable
# Gunakan delimiter | supaya tak gaduh dengan slash (/) dalam path
sed -i "s|^key_name *=.*|key_name = \"$KEY_NAME\"|" ./terraform.tfvars
sed -i "s|^ssh_private_key_path *=.*|ssh_private_key_path = \"$REAL_HOME/.ssh/$KEY_NAME\"|" ./terraform.tfvars

# Cara pro: Cari "# del key-pair", pergi baris bawah (n), then ganti baris tu (s)
sed -i "/# Delete key-pair/{n;s|.*|sudo rm -f \"$REAL_HOME/.ssh/$KEY_NAME\" \"$REAL_HOME/.ssh/$KEY_NAME.pub\"|;}" ./terraform_destroy.sh

# 4. Terraform Action
echo "🔹 Step 3: Terraform Deployment"
#cd "$REAL_HOME/aws-k8s-infra/terraform"

terraform init -reconfigure

# Kita pass variable terus ke Terraform supaya inventory.ini update betul
terraform destroy -var="key_name=$KEY_NAME" -var="ssh_private_key_path=$REAL_HOME/.ssh/$KEY_NAME" -auto-approve || echo "Xda apa nak destroy..."

terraform apply -var="key_name=$KEY_NAME" -var="ssh_private_key_path=$REAL_HOME/.ssh/$KEY_NAME" -auto-approve

echo "-------------------------------------------------------"
echo "🎉 DEPLOYMENT FINISHED!"
echo "-------------------------------------------------------"