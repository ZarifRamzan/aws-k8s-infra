#!/usr/bin/env bash
# ==============================================================================
# ansible_run.sh - Orchestrates service installation & cluster joining
# ==============================================================================
set -e

# ==============================================================================
# Ansible Installation & Update Functions
# ==============================================================================

install_ansible() {
    # Check if ansible exists in PATH
    if command -v ansible &>/dev/null; then
        # Extract version number (handles "ansible 10.4.0" or "ansible [core 2.16.5]")
        CURRENT=$(ansible --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        echo "✅ Ansible found: v${CURRENT}"
        echo "🔄 Proceeding to version check..."
    else
        echo "❌ Ansible not found. Installing latest version..."
    fi
    
    # Delegate to update logic
    install_latest_ansible
}

install_latest_ansible() {
    # 1️ Fetch latest version from PyPI using python3 for reliable JSON parsing
    LATEST=$(curl -s https://pypi.org/pypi/ansible/json 2>/dev/null | \
             python3 -c "import sys, json; print(json.load(sys.stdin)['info']['version'])" 2>/dev/null)

    if [[ -z "$LATEST" ]]; then
        echo "⚠️  Failed to fetch latest version from PyPI. Falling back to pip upgrade..."
        sudo pip3 install --upgrade ansible --break-system-packages 2>/dev/null || \
        sudo pip3 install --upgrade ansible
        return $?
    fi

    # 2️⃣ Get currently installed version (if any)
    CURRENT_VER=""
    if command -v ansible &>/dev/null; then
        CURRENT_VER=$(ansible --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # 3️ Compare versions
    if [[ "$CURRENT_VER" == "$LATEST" ]]; then
        echo "✅ Ansible is already up-to-date (v${LATEST})"
        return 0
    fi

    echo "📥 Installing/Updating: v${CURRENT_VER:-none} → v${LATEST}"

    # 4️⃣ Download & Install
    # Handle Ubuntu 23.04+ externally-managed-environment restriction
    if sudo pip3 install --upgrade "ansible==${LATEST}" --break-system-packages 2>/dev/null; then
        echo "✅ Successfully installed/updated to Ansible v${LATEST}"
    elif sudo pip3 install --upgrade "ansible==${LATEST}" 2>/dev/null; then
        echo "✅ Successfully installed/updated to Ansible v${LATEST}"
    else
        echo "❌ Installation failed. Check pip3 permissions or network."
        return 1
    fi

    # 5️⃣ Verify installation
    INSTALLED_VER=$(ansible --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "$INSTALLED_VER" != "$LATEST" ]]; then
        echo "⚠️  Version mismatch! Expected v${LATEST}, got v${INSTALLED_VER}"
    fi
}

# ==============================================================================
# Execute Functions
# ==============================================================================
install_ansible

cd "$(dirname "$0")"

export ANSIBLE_LOG_PATH="./ansible.log"
INVENTORY="inventory.ini"

# Extract SSH key path from inventory (dynamic, not hardcoded)
SSH_KEY=$(grep 'ansible_ssh_private_key_file' "$INVENTORY" | cut -d'=' -f2 | tr -d ' ')

echo "📦 Step 1: Installing Docker & running services on Build/Monitoring nodes..."
ansible-playbook -i "$INVENTORY" install_services.yml --limit "build,monitoring"

echo "⚙️ Step 2: Installing MicroK8s on Kubernetes nodes..."
ansible-playbook -i "$INVENTORY" install_services.yml --limit "k8s_master,k8s_workers"

echo "🔗 Step 3: Joining workers to Kubernetes cluster..."
ansible-playbook -i "$INVENTORY" join_cluster.yml

echo "🏷️ Step 4: Labeling worker nodes as worker1/worker2..."
# Get Master IP dynamically from inventory
MASTER_IP=$(grep -A1 '\[k8s_master\]' "$INVENTORY" | tail -1)

# Run labeling commands REMOTELY via SSH (non-interactive)
ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ubuntu@"$MASTER_IP" << 'REMOTE_SCRIPT'
  echo "⏳ Waiting 10s for all nodes to be Ready..."
  sleep 10
  
  # Get worker nodes (exclude master) using CORRECT kubectl syntax
  # Note: kubectl uses '!=' for negation, not '!'
  WORKERS=$(microk8s kubectl get nodes -l "role!=master" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || \
            microk8s kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep -v "ip-10-0-1-165")
  
  echo "🔍 Found workers: $WORKERS"
  
  # Label workers sequentially
  COUNT=1
  for NODE in $WORKERS; do
    # Skip if node is NotReady (wait for it)
    STATUS=$(microk8s kubectl get node "$NODE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    if [[ "$STATUS" != "True" ]]; then
      echo "⚠️  Node $NODE is $STATUS, skipping label for now..."
      continue
    fi
    
    echo "🏷️ Labeling $NODE as worker$COUNT..."
    microk8s kubectl label node "$NODE" role=worker$COUNT --overwrite 2>/dev/null || echo "   (Label may already exist)"
    COUNT=$((COUNT + 1))
  done
  
  echo ""
  echo "✅ Final node status & labels:"
  microk8s kubectl get nodes -L role
REMOTE_SCRIPT

echo ""
echo "✅ Ansible provisioning complete!"
echo "📊 Service URLs:"
echo "   🛠️  Jenkins    : http://$(grep -A1 '\[build\]' "$INVENTORY" | tail -1):8080"
echo "   📈 Grafana    : http://$(grep -A1 '\[monitoring\]' "$INVENTORY" | tail -1):3000 (admin/admin123)"
echo "   🔍 Prometheus : http://$(grep -A1 '\[monitoring\]' "$INVENTORY" | tail -1):9090"
echo "   ☸️  K8s Master : ssh -i $SSH_KEY ubuntu@$(grep -A1 '\[k8s_master\]' "$INVENTORY" | tail -1)"
echo ""
echo "# =============================================================================="
echo "# Manual Node Labeling Commands"
echo "# =============================================================================="
echo ""
echo "# SSH to Master"
echo "ssh -i $SSH_KEY ubuntu@$(grep -A1 '\[k8s_master\]' "$INVENTORY" | tail -1)"
echo ""
echo "# Get node information"
echo "microk8s kubectl get nodes -o wide"
echo ""
echo "# Label Worker 1"
echo "e.g"
echo "microk8s kubectl label node <node_ip> role=<tag> --overwrite"
echo "microk8s kubectl label node ip-10-0-1-171 role=worker1 --overwrite"
echo ""
echo "# Label Worker 2"
echo "e.g"
echo "microk8s kubectl label node <node_ip> role=<tag> --overwrite"
echo "microk8s kubectl label node ip-10-0-1-201 role=worker2 --overwrite"
echo ""
echo "# Verify Labels"
echo "microk8s kubectl get nodes -L role"
echo "# =============================================================================="