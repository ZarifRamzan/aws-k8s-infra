ansible_install() {
    echo -e "${BLUE}-------------------------------------------------------${NC}"
    
    # 1. Check if Ansible is already installed
    if command -v ansible &> /dev/null; then
        ANSIBLE_VER=$(ansible --version | head -n 1 | awk '{print $NF}' | tr -d ']')
        echo -e "✅ Ansible is already installed: ${GREEN}v$ANSIBLE_VER${NC}"
    else
        echo -e "🟡 Ansible not found. Installing..."

        # 2. Install prerequisites
        sudo apt-get update -qq
        sudo apt-get install -y software-properties-common -qq

        # 3. Add the official Ansible PPA
        # -y flag automates the "Press [ENTER] to continue" prompt
        sudo add-apt-repository --yes --update ppa:ansible/ansible > /dev/null 2>&1

        # 4. Install Ansible
        sudo apt-get install -y ansible -qq

        # 5. Verification
        if command -v ansible &> /dev/null; then
            echo -e "✨ ${GREEN}Ansible successfully installed!${NC}"
        else
            echo -e "❌ ${RED}Ansible installation failed.${NC}"
            return 1
        fi
    fi
}



# --- Execution Sequence ---
ansible_install

# Run Ansible Test
ansible all -i inventory.ini -m ping

# Run Ansible Run
ansible-playbook -i inventory.ini install_services.yml
ansible-playbook -i inventory.ini join_cluster.yml
