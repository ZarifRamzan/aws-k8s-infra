<div align="center">

# 🚀 AWS Infrastructure — Terraform + Ansible

**Automated cloud infrastructure on AWS Singapore with Kubernetes, Jenkins CI/CD, and Load Balancing**

[![Terraform](https://img.shields.io/badge/Terraform-1.3%2B-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.14%2B-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![MicroK8s](https://img.shields.io/badge/MicroK8s-1.28-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://microk8s.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-LTS-D33833?style=for-the-badge&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

> Fully automated infrastructure-as-code that provisions **5 EC2 instances**, a **custom VPC**, an **Application Load Balancer**, a **MicroK8s cluster**, and a **Dockerised Jenkins** server — all with a single command.

<br/>

[📖 Getting Started](#-getting-started) · [🏗️ Architecture](#️-architecture) · [📁 File Structure](#-file-structure) · [⚙️ Configuration](#️-configuration) · [🚀 Deployment](#-deployment) · [❓ FAQ](#-faq)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Infrastructure Specifications](#-infrastructure-specifications)
- [Prerequisites](#-prerequisites)
- [File Structure](#-file-structure)
- [Configuration](#️-configuration)
- [Getting Started](#-getting-started)
- [Deployment](#-deployment)
- [Accessing Jenkins](#-accessing-jenkins)
- [Ansible Playbooks](#-ansible-playbooks)
- [Outputs](#-outputs)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌐 Overview

This repository contains **Infrastructure as Code (IaC)** that fully automates the provisioning and configuration of a production-ready cloud environment on **AWS Singapore (ap-southeast-1)**.

**Terraform** handles all AWS resource creation — VPC, subnets, security groups, EC2 instances, and load balancer. **Ansible** then takes over to configure every server — installing Docker, spinning up Jenkins via a custom Dockerfile, installing MicroK8s, and forming a Kubernetes cluster automatically.

### ✨ Key Features

| Feature | Details |
|---|---|
| ☁️ **Cloud Provider** | AWS — Singapore Region (`ap-southeast-1`) |
| 🌐 **Networking** | Custom VPC with 2 public subnets across 2 Availability Zones |
| ⚖️ **Load Balancing** | AWS Application Load Balancer (ALB) across worker nodes |
| ☸️ **Kubernetes** | MicroK8s 1.28 cluster (1 master + 2 workers) |
| 🔧 **CI/CD** | Jenkins LTS in Docker with pre-installed plugins |
| 🔒 **State Management** | Remote state in S3 with DynamoDB locking |
| 🤖 **Automation** | Zero manual server configuration — fully Ansible-driven |

---

## 🏗️ Architecture

```
                          ┌─────────────────────────────────────────┐
                          │           AWS ap-southeast-1            │
                          │                                         │
                          │   ┌─────────────────────────────────┐   │
                          │   │        Custom VPC               │   │
                          │   │       10.0.0.0/16               │   │
                          │   │                                 │   │
     Internet             │   │  ┌──────────┐  ┌──────────┐    │   │
         │                │   │  │ Subnet 1 │  │ Subnet 2 │    │   │
         ▼                │   │  │AZ-a      │  │AZ-b      │    │   │
  ┌─────────────┐         │   │  └──────────┘  └──────────┘    │   │
  │   Internet  │         │   │        │              │         │   │
  │   Gateway   │─────────┤   │        └──────┬───────┘         │   │
  └─────────────┘         │   │               │                 │   │
                          │   │               ▼                 │   │
                          │   │   ┌───────────────────────┐     │   │
                          │   │   │  Application Load     │     │   │
                          │   │   │  Balancer  (ALB)      │     │   │
                          │   │   └───────────────────────┘     │   │
                          │   │          │           │           │   │
                          │   │          ▼           ▼           │   │
                          │   │  ┌──────────┐ ┌──────────┐      │   │
                          │   │  │  Worker  │ │  Worker  │      │   │
                          │   │  │  Node 1  │ │  Node 2  │      │   │
                          │   │  │t3.medium │ │t3.medium │      │   │
                          │   │  └──────────┘ └──────────┘      │   │
                          │   │                                  │   │
                          │   │  ┌──────────┐ ┌──────────┐      │   │
                          │   │  │  Master  │ │  Build   │      │   │
                          │   │  │  Node    │ │  Server  │      │   │
                          │   │  │t3.medium │ │ t2.small │      │   │
                          │   │  └──────────┘ └──────────┘      │   │
                          │   │                                  │   │
                          │   │         ┌──────────┐            │   │
                          │   │         │Monitoring│            │   │
                          │   │         │  Server  │            │   │
                          │   │         │ t2.micro │            │   │
                          │   │         └──────────┘            │   │
                          │   └─────────────────────────────────┘   │
                          └─────────────────────────────────────────┘
```

---

## 📊 Infrastructure Specifications

### EC2 Instances

| Server | Instance Type | vCPU | RAM | Storage | Software |
|---|---|---|---|---|---|
| `Build_Server` | t2.small | 1 | 2 GB | 20 GB gp3 | Docker + Jenkins (LTS) |
| `Monitoring_Server` | t2.micro | 1 | 1 GB | 20 GB gp3 | Docker |
| `K8S_Master_Node` | t3.medium | 2 | 4 GB | 30 GB gp3 | MicroK8s (control plane) |
| `K8S_Worker_Node1` | t3.medium | 2 | 4 GB | 30 GB gp3 | MicroK8s (worker) |
| `K8S_Worker_Node2` | t3.medium | 2 | 4 GB | 30 GB gp3 | MicroK8s (worker) |

### Security Group Port Reference

| Security Group | Applied To | Inbound Ports |
|---|---|---|
| `build-sg` | Build_Server | 22 (SSH), 8080 (Jenkins), 50000 (Jenkins Agent) |
| `monitoring-sg` | Monitoring_Server | 22 (SSH), 3000 (Grafana), 9090 (Prometheus), 9100 (Node Exporter - VPC only) |
| `k8s-sg` | All K8s nodes | 22 (SSH), 16443 (K8s API), 10443 (Dashboard), 30000-32767 (NodePort), all traffic within VPC |
| `alb-sg` | Load balancer | 80 (HTTP), 443 (HTTPS) |

---

## ✅ Prerequisites

Ensure the following tools are installed and configured on your local machine before proceeding.

```bash
# Verify all tools are installed
terraform  --version   # >= 1.3.0
ansible    --version   # >= 2.14
aws        --version   # >= 2.0
python3    --version   # >= 3.8
```

| Tool | Installation |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `brew install terraform` / [Download](https://developer.hashicorp.com/terraform/install) |
| [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) | `pip3 install ansible` |
| [AWS CLI](https://aws.amazon.com/cli/) | `pip3 install awscli` |
| [community.docker](https://galaxy.ansible.com/community/docker) | `ansible-galaxy collection install community.docker` |
| [community.general](https://galaxy.ansible.com/community/general) | `ansible-galaxy collection install community.general` |
| [ansible.posix](https://galaxy.ansible.com/ansible/posix) | `ansible-galaxy collection install ansible.posix` |

### AWS Credentials

```bash
aws configure
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name: ap-southeast-1
# Default output format: json
```

### AWS Key Pair

```bash
# Option A — Use an existing key pair (get the name from AWS console)
aws ec2 describe-key-pairs --region ap-southeast-1 --query "KeyPairs[*].KeyName" --output table

# Option B — Create a new key pair
aws ec2 create-key-pair \
  --key-name myproject-key \
  --region ap-southeast-1 \
  --query "KeyMaterial" \
  --output text > ~/.ssh/myproject-key.pem

chmod 400 ~/.ssh/myproject-key.pem
```

---

## 📁 File Structure

```
.
├── terraform/                        # Infrastructure as Code (1046 lines)
│   ├── data.tf                       # Dynamic AMI lookup (latest Ubuntu 22.04)
│   ├── ec2.tf                        # 5 EC2 instances + key pair registration
│   ├── outputs.tf                    # ALB setup + auto-generate Ansible inventory + terminal outputs
│   ├── provider.tf                   # AWS provider + region (local backend active)
│   ├── security_groups.tf            # 4 security groups (build, monitoring, k8s, alb)
│   ├── terraform.tfvars              # ⭐ YOUR VALUES GO HERE — edit before apply
│   ├── variables.tf                  # Variable declarations and defaults
│   └── vpc.tf                        # VPC + 2 subnets + IGW + route tables
│
└── ansible/                          # Configuration Management (772 lines)
    ├── cleanup.yml                   # Cleanup playbook
    ├── install_services.yml          # 5 plays: update all → Docker+Jenkins → Docker+Prometheus+Grafana → microk8s → enable addons
    ├── join_cluster.yml              # 5 plays: form K8s cluster by joining workers to master
    └── inventory.ini                 # Auto-generated by Terraform (DO NOT edit manually)
```

> **⭐ Key Rule:** Only edit `terraform/terraform.tfvars`. All other files are pre-configured and ready to use.

---

## ⚙️ Configuration

Open `terraform/terraform.tfvars` and update the following values:

```hcl
# ─── General ─────────────────────────────────────────────────────────────────
aws_region   = "ap-southeast-1"
project_name = "aws-k8s-infra"       # Change to your project name
environment  = "dev"

# ─── Networking ──────────────────────────────────────────────────────────────
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
public_subnet_2_cidr = "10.0.2.0/24"

# ─── EC2 — UPDATE THESE ──────────────────────────────────────────────────────
key_name             = "YOUR-KEYPAIR-NAME"        # ← Your AWS key pair name
ssh_private_key_path = "~/.ssh/YOUR-KEY"          # ← Path WITHOUT .pem extension

# ─── Instance Types (optional) ───────────────────────────────────────────────
instance_type_build      = "t2.small"   # Build Server (Jenkins)
instance_type_monitoring = "t2.micro"   # Monitoring Server
instance_type_k8s        = "t3.medium"  # All K8s nodes (minimum for microk8s)

# ─── S3 Remote State (currently disabled) ────────────────────────────────────
s3_bucket_name = "DISABLED"
```

> **💡 Note:** The `ssh_private_key_path` should point to your key WITHOUT the `.pem` extension. Terraform will automatically append `.pub` to find the public key for AWS registration.

---

## 🚀 Getting Started

### Step 1 — Clone & Configure

```bash
git clone https://github.com/your-username/your-repo.git
cd your-repo/terraform

# Edit your settings
nano terraform.tfvars
```

### Step 2 — Install Ansible Collections

```bash
ansible-galaxy collection install community.docker community.general ansible.posix
```

### Step 3 — Initialize Terraform

```bash
cd terraform/
terraform init
```

> **Note:** This project uses a **local backend** by default. State is stored in `terraform/terraform.tfstate`. If you want to enable S3 remote state, see the commented section in `provider.tf`.

---

## 🚀 Deployment

### Full Infrastructure Deploy

```bash
cd terraform/

# Preview what will be created (no changes made)
terraform plan

# Deploy everything
terraform apply
```

Expected output after a successful apply:

```
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:
  alb_dns_name = "aws-k8s-infra-alb-xxxxx.ap-southeast-1.elb.amazonaws.com"
  
  ssh_shortcuts = {
    "build"      = "ssh -i ~/.ssh/your-key ubuntu@13.213.x.x"
    "master"     = "ssh -i ~/.ssh/your-key ubuntu@13.213.x.x"
    "monitoring" = "ssh -i ~/.ssh/your-key ubuntu@13.213.x.x"
    "worker1"    = "ssh -i ~/.ssh/your-key ubuntu@13.213.x.x"
    "worker2"    = "ssh -i ~/.ssh/your-key ubuntu@13.213.x.x"
  }
  
  urls = {
    "grafana" = "http://aws-k8s-infra-alb-xxxxx.ap-southeast-1.elb.amazonaws.com/grafana"
    "jenkins" = "http://aws-k8s-infra-alb-xxxxx.ap-southeast-1.elb.amazonaws.com"
  }
```

### Configure Servers with Ansible

```bash
cd ansible/

# Step 1 — Test connectivity to all servers
ansible all -i inventory.ini -m ping

# Step 2 — Install Docker, Jenkins, and MicroK8s
ansible-playbook -i inventory.ini install_services.yml

# Step 3 — Form the Kubernetes cluster
ansible-playbook -i inventory.ini join_cluster.yml
```

> `inventory.ini` is automatically populated with real IPs by Terraform — no manual edits needed.

---

## 🔧 Accessing Jenkins

After `install_services.yml` completes, the playbook prints the Jenkins URL and initial admin password directly in the terminal:

```
TASK [Jenkins install complete] ************************************
ok: [build_server] => {
    "msg": [
        "Jenkins is running!",
        "URL: http://13.213.x.x:8080",
        "Admin password: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    ]
}
```

You can also retrieve the URL from Terraform outputs:

```bash
cd terraform/
terraform output urls

# Get the password by SSHing into the build server
ssh -i ~/.ssh/your-key ubuntu@<BUILD_SERVER_IP>
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Jenkins First-Time Setup

1. Open the Jenkins URL in your browser
2. Enter the initial admin password
3. Click **Install suggested plugins** (or select manually)
4. Create your admin user
5. Jenkins is ready 🎉

---

## 📖 Ansible Playbooks

### `install_services.yml`

Runs 5 sequential plays across your servers:

| Play | Target Group | What It Does |
|---|---|---|
| **Play 1** | `all_servers` | Updates packages, installs common tools (curl, git, vim, htop, etc.) |
| **Play 2** | `build_servers` | Installs Docker CE, writes Dockerfile inline, builds custom Jenkins image, starts container on port 8080 |
| **Play 3** | `monitoring_servers` | Installs Docker CE, creates Prometheus config with all server IPs, runs Prometheus + Grafana containers |
| **Play 4** | `k8s_nodes` | Installs snapd, installs MicroK8s 1.28/stable via snap, adds ubuntu user to microk8s group, creates kubectl alias |
| **Play 5** | `k8s_master` | Enables DNS, storage, dashboard, and ingress add-ons |

### `join_cluster.yml`

| Play | Target | What It Does |
|---|---|---|
| **Play 1** | `k8s_master` | Checks microk8s status, generates join token for Worker 1 |
| **Play 2** | `k8s_worker1` | Checks if already joined, runs join command, waits 30s |
| **Play 3** | `k8s_master` | Generates NEW join token for Worker 2 (tokens are single-use) |
| **Play 4** | `k8s_worker2` | Checks if already joined, runs join command, waits 30s |
| **Play 5** | `k8s_master` | Waits 60s for stabilization, displays all nodes and pods, shows cluster summary |

### Verify Cluster Health

```bash
# SSH into master
ssh -i ~/.ssh/your-key.pem ubuntu@<K8S_MASTER_IP>

# Check all nodes
microk8s kubectl get nodes

# Expected output:
# NAME              STATUS   ROLES    AGE   VERSION
# ip-10-0-1-x       Ready    <none>   5m    v1.28.x
# ip-10-0-1-y       Ready    <none>   3m    v1.28.x
# ip-10-0-1-z       Ready    <none>   3m    v1.28.x
```

---

## 📤 Outputs

| Output | Description |
|---|---|
| `alb_dns_name` | DNS name of the Application Load Balancer |
| `urls` | Map containing Jenkins and Grafana URLs via ALB |
| `ssh_shortcuts` | Map containing ready-to-run SSH commands for all 5 servers |

```bash
# View all outputs at any time
cd terraform/
terraform output

# View a specific output
terraform output urls
terraform output ssh_shortcuts

# Copy an SSH command directly
terraform output -raw ssh_shortcuts | jq -r '.build'
```

---

## 🧹 Teardown

> ⚠️ **Warning:** This will permanently delete ALL resources including servers, networking, and data.

```bash
terraform destroy
```

---

## ❓ FAQ

<details>
<summary><b>Q: I get "InvalidKeyPair.NotFound" error</b></summary>

Your `key_name` in `terraform.tfvars` doesn't match any key pair in AWS. Run the following to see your available key pairs:

```bash
aws ec2 describe-key-pairs --region ap-southeast-1 --query "KeyPairs[*].KeyName" --output table
```

Update `terraform.tfvars` with the exact name shown.

</details>

<details>
<summary><b>Q: How do I enable S3 remote backend?</b></summary>

The project uses a local backend by default. To enable S3 remote state:

1. Create an S3 bucket and DynamoDB table manually or via AWS Console
2. Edit `terraform/provider.tf` — comment out the `backend "local"` block
3. Uncomment the `backend "s3"` block and update the bucket name
4. Run `terraform init -migrate-state` to move your state to S3

</details>

<details>
<summary><b>Q: ALB error — "At least two subnets in two different Availability Zones"</b></summary>

Ensure both `public_subnet_cidr` and `public_subnet_2_cidr` are set in `terraform.tfvars` with different `availability_zone` and `availability_zone_2` values. The ALB requires two subnets in two different AZs.

</details>

<details>
<summary><b>Q: Ansible can't connect to servers</b></summary>

Check the following:

1. Terraform has finished and `inventory.ini` has been generated with real IPs
2. Your `.pem` file has correct permissions: `chmod 400 ~/.ssh/your-key.pem`
3. Test basic connectivity: `ansible all -i inventory.ini -m ping`
4. Ensure port 22 is open in your security group (it is by default in this config)

</details>

<details>
<summary><b>Q: Where is the Jenkins initial admin password?</b></summary>

SSH into the Build Server and run:

```bash
# Get the SSH command from Terraform
cd terraform/
terraform output -json ssh_shortcuts | jq -r '.build'

# SSH in and get the password
ssh -i ~/.ssh/your-key ubuntu@<BUILD_SERVER_IP>
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

</details>

<details>
<summary><b>Q: How do I re-run just the Ansible playbooks without re-creating servers?</b></summary>

Ansible playbooks are idempotent — safe to re-run at any time without side effects:

```bash
cd ansible/
ansible-playbook -i inventory.ini install_services.yml
ansible-playbook -i inventory.ini join_cluster.yml
```

</details>

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

Please ensure your code follows existing conventions and all `terraform validate` checks pass before submitting.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ using Terraform, Ansible, and AWS**

⭐ Star this repo if it helped you!

</div>