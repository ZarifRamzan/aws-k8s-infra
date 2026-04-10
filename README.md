<div align="center">

# 🚀 AWS Infrastructure — Terraform + Ansible

**Automated cloud infrastructure on AWS Singapore with Kubernetes, Jenkins CI/CD, and Load Balancing**

[![Terraform](https://img.shields.io/badge/Terraform-1.3%2B-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-2.14%2B-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![AWS](https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![MicroK8s](https://img.shields.io/badge/MicroK8s-1.29-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://microk8s.io/)
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
| ☸️ **Kubernetes** | MicroK8s 1.29 cluster (1 master + 2 workers) |
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
| `general-sg` | All servers | 22 (SSH), 8080 (Jenkins), 50000 (Jenkins Agent) |
| `microk8s-sg` | K8s nodes | 16443, 25000, 19001, 10250-10255, 30000-32767, 4789/UDP |
| `monitoring-sg` | Monitoring server | 9090 (Prometheus), 3000 (Grafana) |
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
terraform/
├── ansible/                          # Ansible configuration & playbooks
│   ├── files/
│   │   └── Dockerfile.jenkins        # Custom Jenkins image (Docker CLI + plugins)
│   ├── install_services.yml          # Install Docker, Jenkins, MicroK8s
│   ├── inventory.ini                 # Server inventory (auto-generated by Terraform)
│   └── join_cluster.yml              # Form the MicroK8s cluster
│
├── templates/
│   └── inventory.tftpl               # Inventory template (filled by Terraform)
│
├── data.tf                           # Dynamic AMI lookup (latest Ubuntu 22.04)
├── ec2.tf                            # EC2 instances + ALB + inventory generation
├── outputs.tf                        # Print IPs, URLs, SSH commands after apply
├── provider.tf                       # AWS provider + region + remote backend
├── s3.tf                             # S3 bucket + DynamoDB for Terraform state
├── security_groups.tf                # Firewall rules for all server types
├── terraform.tfstate                 # Local state (managed automatically)
├── terraform.tfstate.backup          # State backup (managed automatically)
├── terraform.tfvars                  # ⭐ YOUR VALUES GO HERE — edit before apply
├── variables.tf                      # Variable declarations and defaults
└── vpc.tf                            # VPC, subnets, IGW, route tables
```

> **⭐ Key Rule:** Only edit `terraform.tfvars`. All other `.tf` files are pre-configured and ready to use.

---

## ⚙️ Configuration

Open `terraform.tfvars` and update the following values:

```hcl
# ─── General ─────────────────────────────────────────────────────────────────
aws_region   = "ap-southeast-1"
project_name = "myproject"           # Change to your project name
environment  = "dev"

# ─── Networking ──────────────────────────────────────────────────────────────
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
public_subnet_2_cidr = "10.0.2.0/24"
availability_zone    = "ap-southeast-1a"
availability_zone_2  = "ap-southeast-1b"

# ─── EC2 — UPDATE THESE ──────────────────────────────────────────────────────
key_name = "YOUR-KEYPAIR-NAME"        # ← Your AWS key pair name
ami_id   = "ami-0df7a207adb9748c7"    # Ubuntu 22.04 LTS Singapore

# ─── S3 Remote State — UPDATE THIS ───────────────────────────────────────────
state_bucket_name = "myproject-tfstate-YOUR-ACCOUNT-ID"   # ← Must be globally unique

# ─── Ansible / SSH — UPDATE THIS ─────────────────────────────────────────────
ssh_private_key_path = "~/.ssh/YOUR-KEY.pem"   # ← Path to your .pem file
ansible_user         = "ubuntu"
```

> **💡 Tip:** Make your S3 bucket name unique by appending your AWS Account ID.
> Find it with: `aws sts get-caller-identity --query Account --output text`

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

### Step 3 — Bootstrap Remote State

> Run this once to create the S3 bucket and DynamoDB table before using the remote backend.

```bash
terraform init

terraform apply \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_dynamodb_table.terraform_lock
```

Then uncomment the `backend "s3"` block in `provider.tf` and migrate the state:

```bash
terraform init -migrate-state
```

---

## 🚀 Deployment

### Full Infrastructure Deploy

```bash
# Preview what will be created (no changes made)
terraform plan

# Deploy everything
terraform apply
```

Expected output after a successful apply:

```
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:
  build_server_public_ip    = "13.213.x.x"
  monitoring_server_public_ip = "13.213.x.x"
  k8s_master_public_ip      = "13.213.x.x"
  k8s_worker1_public_ip     = "13.213.x.x"
  k8s_worker2_public_ip     = "13.213.x.x"
  alb_dns_name              = "myproject-alb-xxxxx.ap-southeast-1.elb.amazonaws.com"
  jenkins_url               = "http://13.213.x.x:8080"
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
==========================================
  Jenkins is UP!
  URL     : http://13.213.x.x:8080
  Password: a1b2c3d4e5f6789abcdef...
==========================================
```

You can also retrieve these at any time:

```bash
# Get Jenkins URL
terraform output jenkins_url

# Get the command to retrieve the initial admin password
terraform output jenkins_initial_password_cmd

# Run that command to get the password
ssh -i ~/.ssh/your-key.pem ubuntu@<BUILD_SERVER_IP> \
  'docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword'
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

Runs 4 sequential plays across your servers:

| Play | Target Group | What It Does |
|---|---|---|
| **Play 1** | `docker_hosts` | Updates packages, installs Docker CE on Build + Monitoring servers |
| **Play 2** | `build` | Builds custom Jenkins image from Dockerfile, starts container on port 8080 |
| **Play 3** | `k8s` | Installs MicroK8s 1.29/stable on all 3 Kubernetes nodes |
| **Play 4** | `k8s_master` | Enables DNS, storage, metrics-server, and ingress add-ons |

### `join_cluster.yml`

| Play | Target | What It Does |
|---|---|---|
| **Play 1** | `k8s_master` | Generates unique join tokens for each worker |
| **Play 2** | `K8S_Worker_Node1` | Runs join command to enter the cluster |
| **Play 3** | `K8S_Worker_Node2` | Runs join command to enter the cluster |
| **Play 4** | `k8s_master` | Polls until all 3 nodes show `Ready` status |

### Verify Cluster Health

```bash
# SSH into master
ssh -i ~/.ssh/your-key.pem ubuntu@<K8S_MASTER_IP>

# Check all nodes
microk8s kubectl get nodes

# Expected output:
# NAME              STATUS   ROLES    AGE   VERSION
# K8S_Master_Node   Ready    <none>   5m    v1.29.x
# K8S_Worker_Node1  Ready    <none>   3m    v1.29.x
# K8S_Worker_Node2  Ready    <none>   3m    v1.29.x
```

---

## 📤 Outputs

| Output | Description |
|---|---|
| `build_server_public_ip` | Public IP of Build_Server |
| `monitoring_server_public_ip` | Public IP of Monitoring_Server |
| `k8s_master_public_ip` | Public IP of K8S_Master_Node |
| `k8s_worker1_public_ip` | Public IP of K8S_Worker_Node1 |
| `k8s_worker2_public_ip` | Public IP of K8S_Worker_Node2 |
| `k8s_master_private_ip` | Private IP of master (used internally by K8s) |
| `alb_dns_name` | DNS name of the Application Load Balancer |
| `jenkins_url` | Direct URL to Jenkins Web UI |
| `jenkins_initial_password_cmd` | Command to retrieve Jenkins admin password |
| `ssh_build_server` | Ready-to-run SSH command for Build_Server |
| `ssh_k8s_master` | Ready-to-run SSH command for K8S_Master_Node |
| `state_bucket_name` | S3 bucket used for Terraform state |

```bash
# View all outputs at any time
terraform output

# View a specific output
terraform output jenkins_url
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
<summary><b>Q: I get "BucketAlreadyExists" error for S3</b></summary>

S3 bucket names are globally unique across all AWS accounts. Change `state_bucket_name` in `terraform.tfvars` to something unique — appending your AWS Account ID works well:

```bash
# Get your account ID
aws sts get-caller-identity --query Account --output text

# Then set:
state_bucket_name = "myproject-tfstate-<YOUR-ACCOUNT-ID>"
```

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

Run this command — it SSHs into the Build Server and prints the password:

```bash
$(terraform output -raw jenkins_initial_password_cmd)
```

Or manually:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<BUILD_SERVER_IP> \
  'docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword'
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