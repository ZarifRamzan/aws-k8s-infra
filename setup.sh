#!/usr/bin/env bash
set -euo pipefail

# 🔧 Auto-fix .env if stuck from previous sudo/root run
if [[ -f .env ]] && [[ ! -w .env ]]; then
    sudo chown "$(whoami):$(id -gn)" .env 2>/dev/null || sudo chmod 600 .env 2>/dev/null || { echo "❌ Run: sudo chown \$USER .env"; exit 1; }
fi
chmod 600 .env 2>/dev/null || true

# 1. Install / Update AWS CLI v2
if command -v aws >/dev/null && aws --version 2>&1 | grep -q "aws-cli/2"; then
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o aws.zip
    unzip -q -o aws.zip && sudo ./aws/install --update && rm -rf aws aws.zip
    echo "✅ Updated: $(aws --version)"
else
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o aws.zip
    unzip -q aws.zip && sudo ./aws/install && rm -rf aws aws.zip
    echo "✅ Installed: $(aws --version)"
fi

# 2. Credentials Setup
[[ -f .env ]] && set -a && source .env && set +a

if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
    echo -e "\n📂 Found existing credentials:"
    echo "   Region: ${AWS_DEFAULT_REGION:-us-east-1}"
    echo "   Account: $(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo 'unknown')"
    read -rp "Use existing credentials? (Y/n): " reuse
    if [[ "$reuse" == "n" || "$reuse" == "N" ]]; then
        echo "🗑️  Removing old .env to reconfigure..."
        rm -f .env
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    fi
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
    echo -e "\n🔐 Enter AWS credentials:"
    read -p "Access Key ID: " AK
    read -s -p "Secret Access Key: " SK && echo
    read -p "Default Region [us-east-1]: " REG
    REG="${REG:-us-east-1}"
    
    cat > .env <<EOF
AWS_ACCESS_KEY_ID=$AK
AWS_SECRET_ACCESS_KEY=$SK
AWS_DEFAULT_REGION=$REG
AWS_DEFAULT_OUTPUT=json
EOF
    chmod 600 .env
    set -a; source .env; set +a
    echo "✅ Credentials saved to .env"
fi

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set default.region "$AWS_DEFAULT_REGION"
aws sts get-caller-identity >/dev/null && echo "✅ Connected" || { echo "❌ Failed"; exit 1; }

# 3. Key-Pair Setup
REG="${AWS_DEFAULT_REGION:-us-east-1}"
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

AWS_KEYS=$(aws ec2 describe-key-pairs --region "$REG" --query 'KeyPairs[].KeyName' --output text 2>/dev/null | tr '\t ' '\n' | grep -v '^$' || true)
LOCAL_KEYS=$(find "$SSH_DIR" -maxdepth 1 -name "*.pem" -type f 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.pem$//' | sort -u || true)

VALID_KEYS=""
if [[ -n "$AWS_KEYS" && -n "$LOCAL_KEYS" ]]; then
    VALID_KEYS=$(comm -12 <(echo "$AWS_KEYS" | sort) <(echo "$LOCAL_KEYS" | sort) || true)
fi

echo -e "\n📋 Keys in AWS ($REG):"
[[ -n "$AWS_KEYS" ]] && echo "$AWS_KEYS" | while read -r k; do echo "  • $k"; done || echo "  (none)"

echo -e "\n🔐 Local PEM files (~/.ssh/):"
[[ -n "$LOCAL_KEYS" ]] && echo "$LOCAL_KEYS" | while read -r k; do echo "  • $k.pem"; done || echo "  (none)"

echo -e "\n✅ Ready to use (exist in BOTH AWS + local):"
[[ -n "$VALID_KEYS" ]] && echo "$VALID_KEYS" | while read -r k; do echo "  • $k.pem"; done || echo "  (none)"

echo -e "\n[1] Use existing (valid key)  [2] Create new"
read -rp "Choice: " c

case "$c" in
    1)
        if [[ -z "$VALID_KEYS" ]]; then echo "❌ No valid keys found!"; exit 1; fi
        echo "Available keys:"; echo "$VALID_KEYS" | nl
        read -rp "Enter key name: " KN
        echo "$VALID_KEYS" | grep -qx "$KN" || { echo "❌ Invalid"; exit 1; }
        PEM="$SSH_DIR/$KN.pem"; chmod 400 "$PEM"
        PUB="$SSH_DIR/$KN.pub"; chmod 400 "$PUB"
        ;;
    2)
        read -rp "New key name: " KN
        PEM="$SSH_DIR/$KN.pem"
        PUB="$SSH_DIR/$KN.pub"
        
        echo "$AWS_KEYS" | grep -qx "$KN" && { echo "⚠️ Exists in AWS. Use different name."; exit 1; }
        echo "🔨 Creating key-pair '$KN'..."
        
        if aws ec2 create-key-pair --key-name "$KN" --region "$REG" --query 'KeyMaterial' --output text > "$PEM" 2>/dev/null; then
            chmod 400 "$PEM"
            chown "$(id -u):$(id -g)" "$PEM" 2>/dev/null || true
            
            # Generate public key from PEM
            if command -v ssh-keygen >/dev/null 2>&1; then
                ssh-keygen -y -f "$PEM" > "$PUB" 2>/dev/null && chmod 644 "$PUB"
            fi
            
            echo "✅ Created: $PEM"
            [[ -f "$PUB" ]] && echo "✅ Generated: $PUB"
        else
            echo "❌ Failed to create key-pair"
            exit 1
        fi
        ;;
    *) echo "❌ Invalid choice"; exit 1 ;;
esac

echo -e "\n📍 PEM: $PEM"
[[ -f "${PUB:-}" ]] && echo "📍 PUB: $PUB"
echo "🔐 Perms: $(stat -c '%a' "$PEM") | Owner: $(id -un)"
echo "✅ Done."

# Replace existing line in terraform.tfvars for project specific
sed -i "s|^key_pair_public_path\s*=.*|key_pair_public_path = \"${PUB}\"|" terraform/terraform.tfvars
sed -i "s|^ssh_private_key_path\s*=.*|ssh_private_key_path = \"${PEM}\"|" terraform/terraform.tfvars

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Helper Functions
# ==============================================================================
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

check_inventory() {
    [[ -f "$SCRIPT_DIR/ansible/inventory.ini" ]] && return 0 || return 1
}

check_terraform_state() {
    [[ -f "$SCRIPT_DIR/terraform/terraform.tfstate" ]] && return 0 || return 1
}

# ==============================================================================
# Menu Actions
# ==============================================================================
run_terraform_full() {
    print_header "🚀 Running Full Deployment (Terraform)"
    
    echo "📋 This will:"
    echo "   1. Initialize & apply Terraform (create AWS resources)"
    echo "   2. Generate Ansible inventory from Terraform outputs"
    echo "   3. Run Ansible playbooks (install Docker, MicroK8s, Jenkins, Grafana)"
    echo ""
    
    read -rp "Continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_warning "Deployment cancelled"
        return 0
    fi
    
    echo ""
    if bash "$SCRIPT_DIR/terraform/terraform_run.sh"; then
        print_success "✅ Full deployment completed successfully!"
        echo ""
        echo "📊 Access your services:"
        echo "   Jenkins    : http://<BUILD_IP>:8080"
        echo "   Grafana    : http://<MONITOR_IP>:3000 (admin/admin123)"
        echo "   Prometheus : http://<MONITOR_IP>:9090"
        echo "   K8s Master : ssh -i ~/.ssh/*.pem ubuntu@<MASTER_IP>"
        echo ""
        echo "💡 Tip: Run 'terraform/terraform_destroy.sh' to clean up"
    else
        print_error "❌ Deployment failed. Check logs above"
        return 1
    fi
}

run_ansible_only() {
    print_header "🤖 Running Ansible (Re-configure existing infrastructure)"
    
    # Prerequisite check
    if ! check_inventory; then
        print_error "inventory.ini not found!"
        echo ""
        echo "💡 Ansible needs an inventory file with server IPs."
        echo "   This is auto-generated by Terraform."
        echo ""
        read -rp "Run Terraform first to generate inventory? (y/N): " run_tf
        if [[ "$run_tf" == "y" || "$run_tf" == "Y" ]]; then
            run_terraform_full
            return $?
        else
            print_warning "Ansible cannot run without inventory. Returning to menu."
            return 0
        fi
    fi
    
    echo "📋 This will:"
    echo "   1. Install Docker & run services (Jenkins, Grafana, Prometheus)"
    echo "   2. Install MicroK8s on Kubernetes nodes"
    echo "   3. Join workers to the cluster & label nodes"
    echo ""
    echo "📁 Using inventory: $SCRIPT_DIR/ansible/inventory.ini"
    echo ""
    
    read -rp "Continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_warning "Ansible run cancelled"
        return 0
    fi
    
    echo ""
    if bash "$SCRIPT_DIR/ansible/ansible_run.sh"; then
        print_success "✅ Ansible configuration completed!"
    else
        print_error "❌ Ansible failed. Check logs above"
        return 1
    fi
}

run_cleanup() {
    print_header "🗑️  Cleaning Up Infrastructure (Destructive!)"
    
    echo -e "${RED}⚠️  WARNING: This will IRREVERSIBLY destroy:${NC}"
    echo "   • All AWS resources (EC2, VPC, ALB, S3)"
    echo "   • All data on instances (Jenkins jobs, Prometheus metrics, K8s workloads)"
    echo "   • Local Terraform state & Ansible inventory"
    echo ""
    echo "📋 Cleanup steps:"
    echo "   1. Run Ansible cleanup.yml (stop containers, remove MicroK8s)"
    echo "   2. Run Terraform destroy (remove AWS resources)"
    echo "   3. Delete local state files & inventory"
    echo ""
    
    read -rp "Type 'DESTROY' to confirm: " confirm
    if [[ "$confirm" != "DESTROY" ]]; then
        print_warning "Cleanup cancelled"
        return 0
    fi
    
    echo ""
    echo "🔄 Step 1: Running Ansible cleanup..."
    if ansible-playbook -i "$SCRIPT_DIR/ansible/inventory.ini" "$SCRIPT_DIR/ansible/cleanup.yml" 2>/dev/null; then
        print_success "✅ Ansible cleanup completed"
    else
        print_warning "⚠️  Ansible cleanup skipped (inventory may be stale)"
    fi
    
    echo ""
    echo "🔄 Step 2: Running Terraform destroy..."
    if bash "$SCRIPT_DIR/terraform/terraform_destroy.sh"; then
        print_success "✅ Terraform destroy completed"
    else
        print_error "❌ Terraform destroy failed"
        return 1
    fi
    
    echo ""
    print_success "🎉 Cleanup complete! All resources destroyed."
    echo "💡 You can now run 'terraform_run.sh' to start fresh"
}

show_help() {
    print_header "📚 Help & Information"
    echo "Available commands:"
    echo "  [1] Run Terraform  → Full deploy: AWS infra + Ansible config"
    echo "  [2] Run Ansible    → Re-configure existing servers (needs inventory)"
    echo "  [3] Clean Up       → Destroy everything (irreversible!)"
    echo "  [h] Show Help      → This message"
    echo "  [q] Quit           → Exit the menu"
    echo ""
    echo "📁 Project structure:"
    echo "  terraform/     → AWS infrastructure (VPC, EC2, ALB)"
    echo "  ansible/       → Server configuration (Docker, MicroK8s, Jenkins)"
    echo "  .env           → AWS credentials (NEVER commit)"
    echo "  main.sh        → This menu script"
    echo ""
    echo "🔐 Security tips:"
    echo "  • Keep .env and *.pem files private"
    echo "  • Rotate AWS keys if accidentally committed"
    echo "  • Use terraform.tfvars.example for documentation"
}

# ==============================================================================
# Main Menu Loop
# ==============================================================================
main_menu() {
    while true; do
        print_header "AWS Kubernetes Infrastructure Automation"
        
        echo "Choose an action:"
        echo "  [1] 🚀 Run Terraform (Full Deploy)"
        echo "  [2] 🤖 Run Ansible Only (Re-configure)"
        echo "  [3] 🗑️  Clean Up (Destroy Everything)"
        echo "  [h] 📚 Show Help"
        echo "  [q] ❌ Quit"
        echo ""
        
        read -rp "Enter choice [1/2/3/h/q]: " choice
        echo ""
        
        case "$choice" in
            1)
                run_terraform_full
                ;;
            2)
                run_ansible_only
                ;;
            3)
                run_cleanup
                ;;
            h|H|help)
                show_help
                ;;
            q|Q|quit|exit)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                print_warning "Invalid choice. Please enter 1, 2, 3, h, or q"
                ;;
        esac
        
        # Pause before returning to menu (unless exiting)
        if [[ "$choice" != "q" && "$choice" != "Q" ]]; then
            echo ""
            read -rp "Press Enter to return to menu..."
            clear 2>/dev/null || true
        fi
    done
}

# ==============================================================================
# Entry Point
# ==============================================================================
# Verify we're in the project root
if [[ ! -f "$SCRIPT_DIR/terraform/provider.tf" ]]; then
    print_error "main.sh must be run from project root"
    echo "💡 Expected structure:"
    echo "   ~/aws-k8s-infra/"
    echo "   ├── main.sh ← Run this"
    echo "   ├── terraform/"
    echo "   └── ansible/"
    exit 1
fi

# Check for .env (warn but don't block)
if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
    print_warning ".env not found. AWS commands may fail."
    echo "💡 Create .env with:"
    echo "   AWS_ACCESS_KEY_ID=your_key"
    echo "   AWS_SECRET_ACCESS_KEY=your_secret"
    echo "   AWS_DEFAULT_REGION=ap-southeast-1"
    echo ""
    read -rp "Continue anyway? (y/N): " cont
    if [[ "$cont" != "y" && "$cont" != "Y" ]]; then
        exit 1
    fi
fi

# Start the menu
main_menu
