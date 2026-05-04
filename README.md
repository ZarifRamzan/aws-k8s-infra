<h1 align="center">🚀 AWS Kubernetes Infrastructure v2 — Terraform + Ansible</h1>

<div align="center">
  <a href="https://www.terraform.io/"><img src="https://img.shields.io/badge/Terraform-1.3%2B-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"></a>
  <a href="https://www.ansible.com/"><img src="https://img.shields.io/badge/Ansible-2.14%2B-EE0000?style=for-the-badge&logo=ansible&logoColor=white" alt="Ansible"></a>
  <a href="https://aws.amazon.com/"><img src="https://img.shields.io/badge/AWS-ap--southeast--1-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS"></a>
  <a href="https://microk8s.io/"><img src="https://img.shields.io/badge/MicroK8s-1.28-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="MicroK8s"></a>
  <a href="https://www.jenkins.io/"><img src="https://img.shields.io/badge/Jenkins-LTS-D33833?style=for-the-badge&logo=jenkins&logoColor=white" alt="Jenkins"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"></a>
</div>

> **What this project does in one sentence:** Run a single script and it automatically builds a complete cloud environment on AWS — 5 servers, a load balancer, a Kubernetes cluster, a Jenkins CI/CD pipeline, and a Grafana monitoring dashboard — all from code.

---

## 📑 Table of Contents

1. [What Is This Project?](#1-what-is-this-project)
2. [What Gets Built?](#2-what-gets-built)
3. [How the Two Tools Work Together](#3-how-the-two-tools-work-together)
4. [Prerequisites — What You Need Before Starting](#4-prerequisites--what-you-need-before-starting)
5. [Quick Start — First Time Setup](#5-quick-start--first-time-setup)
6. [Typical Workflow](#6-typical-workflow)
7. [Repository Structure](#7-repository-structure)
8. [Terraform Files — Explained](#8-terraform-files--explained)
9. [Ansible Files — Explained](#9-ansible-files--explained)
10. [Automation Scripts — Explained](#10-automation-scripts--explained)
11. [Configuration Reference](#11-configuration-reference)
12. [Accessing Your Services After Deployment](#12-accessing-your-services-after-deployment)
13. [Destroying Everything (Clean Up)](#13-destroying-everything-clean-up)
14. [Troubleshooting Common Issues](#14-troubleshooting-common-issues)
15. [Security Notes](#15-security-notes)

---

## 1. What Is This Project?

This is an **Infrastructure-as-Code (IaC)** project. Instead of logging into the AWS website and clicking buttons to create servers and networks, you write code that describes what you want, and the tools build it for you automatically.

### Why is this better than clicking in the AWS console?

| Problem with Manual Clicking | How IaC Solves It |
|---|---|
| Takes 30–60 minutes of clicking | Done in ~15 minutes automatically |
| Easy to make mistakes | Code is consistent every time |
| Hard to recreate later | Run the script again anytime |
| Hard to share with teammates | Everyone uses the same code |
| No record of what was changed | Git tracks every change |

### The Two Main Tools

| Tool | Job | Simple Analogy |
|---|---|---|
| **Terraform** | Creates the AWS infrastructure (servers, networks, load balancer, storage) | A construction crew that builds the house |
| **Ansible** | Configures the servers after they exist (installs software, starts services) | An interior designer who furnishes and sets up the house |

---

## 2. What Gets Built?

### 5 EC2 Servers (Virtual Machines)

| Server Name | Size | Purpose | Software Installed |
|---|---|---|---|
| `Build_Server` | t2.small (1 vCPU, 2 GB RAM) | Runs CI/CD pipelines | Docker + Jenkins |
| `Monitoring_Server` | t2.micro (1 vCPU, 1 GB RAM) | Monitors system health | Docker + Prometheus + Grafana |
| `K8S_Master_Node` | t3.medium (2 vCPU, 4 GB RAM) | Kubernetes control plane (brain) | MicroK8s (master mode) |
| `K8S_Worker_Node1` | t3.medium (2 vCPU, 4 GB RAM) | Runs your containerised apps | MicroK8s (worker mode) |
| `K8S_Worker_Node2` | t3.medium (2 vCPU, 4 GB RAM) | Runs your containerised apps | MicroK8s (worker mode) |

> **What is t3.medium?** AWS names their server sizes like `t3.medium`. The letter is the family (t = general purpose), the number is the generation (3 = third gen), and the word is the size. Medium = 2 CPUs and 4 GB RAM.

### Networking

| Resource | Details | Purpose |
|---|---|---|
| **VPC** | `10.0.0.0/16` (65,536 IPs) | Your private, isolated cloud network |
| **Public Subnet A** | `10.0.1.0/24` in Zone A | Where all 5 servers live |
| **Public Subnet B** | `10.0.2.0/24` in Zone B | Required by the load balancer |
| **Internet Gateway** | Attached to VPC | The door connecting your network to the internet |
| **Route Table** | Points `0.0.0.0/0` → Internet Gateway | The GPS routing traffic correctly |

### Other Resources

| Resource | Details |
|---|---|
| **Application Load Balancer (ALB)** | Internet-facing, distributes HTTP traffic across all servers on port 80 |
| **S3 Bucket** | Versioned + KMS-encrypted, used for Terraform state or build artifacts |
| **Security Groups** | `ec2_sg` (ports 22, 8080, 3000, 9090, 16443, 25000) + `alb_sg` (port 80) |
| **SSH Key Pair** | Imported from your local public key — used to SSH into all servers |

### Services Installed by Ansible

| Service | Server | Port | What It Does |
|---|---|---|---|
| **Jenkins** | Build_Server | `8080` | Runs automated build/test/deploy pipelines |
| **Prometheus** | Monitoring_Server | `9090` | Collects metrics from all servers |
| **Grafana** | Monitoring_Server | `3000` | Visualises metrics as dashboards |
| **MicroK8s** | Master + Workers | `16443` | Lightweight Kubernetes cluster |

---

## 3. How the Two Tools Work Together

```
You run: ./setup.sh
         │
         ├─► Installs AWS CLI, sets up credentials and SSH keys
         │
         ├─► MENU OPTION 1 → runs terraform/terraform_run.sh
         │       │
         │       ├─► terraform init   (downloads AWS provider plugin)
         │       ├─► terraform plan   (previews what will be created)
         │       ├─► terraform apply  (creates everything in AWS)
         │       └─► Generates ansible/inventory.ini with real server IPs
         │
         └─► MENU OPTION 2 → runs ansible/ansible_run.sh
                 │
                 ├─► Connects to Build + Monitoring servers via SSH
                 │       └─► Installs Docker, Jenkins, Prometheus, Grafana
                 │
                 ├─► Connects to K8s Master + Workers via SSH
                 │       └─► Installs MicroK8s
                 │
                 └─► Joins Worker1 + Worker2 to the cluster
```

---

## 4. Prerequisites — What You Need Before Starting

### Your Computer Requirements
- **OS:** Linux or macOS (scripts use `bash`). On Windows, use WSL2.
- **Internet connection** (to download tools and reach AWS)

### Tools to Install

The `setup.sh` script installs AWS CLI automatically. You need to install these yourself first:

```bash
# Install required system tools (Ubuntu/Debian)
sudo apt update
sudo apt install -y curl wget unzip jq ssh

# Install Terraform (setup.sh also does this, but just in case)
# Visit: https://developer.hashicorp.com/terraform/install

# Install Ansible
sudo pip3 install ansible --break-system-packages

# Install required Ansible collections (run this once)
ansible-galaxy collection install community.general community.docker
```

### AWS Account Requirements
- An active AWS account
- An IAM user with programmatic access (Access Key + Secret Key)
- The IAM user needs permissions to create: EC2, VPC, S3, IAM (key pairs), Load Balancers

> **How to create AWS Access Keys:** AWS Console → IAM → Users → Your User → Security Credentials → Create Access Key → Choose "CLI" → Download the CSV file.

---

## 5. Quick Start — First Time Setup

### Step 1 — Clone the repository

```bash
git clone <your-repo-url>
cd aws-k8s-infra-v2
```

### Step 2 — Run the bootstrap script

```bash
./setup.sh
```

This script will interactively guide you through:

1. **Installing/updating AWS CLI v2** — automatically
2. **Entering AWS credentials** — you will be prompted for:
   - `Access Key ID` (looks like `AKIA...`)
   - `Secret Access Key` (long string)
   - `Default Region` (press Enter for `ap-southeast-1` / Singapore)
3. **SSH Key setup** — choose to create a new key or reuse an existing one
4. **Updating `terraform.tfvars`** — the key paths are patched automatically

After setup, you land on the main menu:

```
[1] 🚀 Run Terraform (Full Deploy)
[2] 🤖 Run Ansible Only (Re-configure)
[3] 🗑️  Clean Up (Destroy Everything)
[h] 📚 Show Help
[q] ❌ Quit
```

### Step 3 — Deploy infrastructure

Choose **`[1]`** to run the full deployment. This will:
- Create all AWS resources with Terraform (~5–10 minutes)
- Generate `ansible/inventory.ini` with real server IP addresses
- Install all software on the servers with Ansible (~10–15 minutes)

### Step 4 — Access your services

After the script finishes, you will see output like:

```
🛠️  Jenkins    : http://13.212.x.x:8080
📈 Grafana    : http://54.255.x.x:3000  (admin / admin123)
🔍 Prometheus : http://54.255.x.x:9090
☸️  K8s Master : ssh -i ~/.ssh/yourkey.pem ubuntu@18.141.x.x
```

---

## 6. Typical Workflow

```bash
# 1. First time: full setup
./setup.sh                         # Sets up credentials + SSH keys
# Choose [1] → Terraform + Ansible deploy

# 2. Already have infrastructure, just re-run Ansible
./setup.sh
# Choose [2] → Ansible only

# 3. Validate your AWS credentials are working
./terraform/validate_credentials.sh

# 4. Tear down everything when done (saves money!)
./setup.sh
# Choose [3] → Destroy everything
# OR run directly:
./terraform/terraform_destroy.sh
```

---

## 7. Repository Structure

```
aws-k8s-infra-v2/
│
├── setup.sh                        ← 🚀 START HERE — main bootstrap + menu
├── .env                            ← AWS credentials (⚠️ NEVER commit this)
├── .gitignore                      ← Tells Git to ignore secrets & temp files
│
├── terraform/                      ← Infrastructure code (creates AWS resources)
│   ├── provider.tf                 ← Tells Terraform to use AWS + Singapore region
│   ├── variables.tf                ← Declares all configurable settings
│   ├── terraform.tfvars            ← ⭐ YOUR values for those settings (edit this)
│   ├── vpc.tf                      ← Creates the private network
│   ├── ec2.tf                      ← Creates the 5 servers
│   ├── security_groups.tf          ← Creates firewall rules
│   ├── load_balancer.tf            ← Creates the Application Load Balancer
│   ├── s3.tf                       ← Creates encrypted S3 storage bucket
│   ├── data.tf                     ← Fetches Ubuntu AMI + imports SSH key
│   ├── outputs.tf                  ← Prints server IPs + connection commands
│   ├── .terraform.lock.hcl         ← Locks provider versions (commit this!)
│   ├── terraform_run.sh            ← Runs Terraform + generates Ansible inventory
│   ├── terraform_destroy.sh        ← Destroys all AWS resources
│   ├── validate_credentials.sh     ← Tests your AWS credentials work
│   └── aws_god_mode_cleanup.sh     ← ⚠️ NUCLEAR option: destroys everything
│
└── ansible/                        ← Configuration code (installs software)
    ├── install_services.yml        ← Installs Docker, Jenkins, Grafana, MicroK8s
    ├── join_cluster.yml            ← Forms the Kubernetes cluster
    ├── cleanup.yml                 ← Removes all installed services
    ├── ansible_run.sh              ← Runs all Ansible playbooks in order
    ├── inventory.ini               ← Server IP list (auto-generated, don't edit)
    └── tools/
        ├── Dockerfile.jenkins      ← Custom Jenkins image with Docker CLI + plugins
        ├── Dockerfile.grafana      ← Custom Grafana image with Prometheus pre-wired
        ├── plugins.txt             ← List of Jenkins plugins to install
        └── datasources.yml        ← Grafana → Prometheus connection config
```

---

## 8. Terraform Files — Explained

### `provider.tf` — Connecting Terraform to AWS

**What it does:** This is the first file Terraform reads. It tells Terraform which cloud provider to talk to (AWS) and sets default tags that are added to every resource it creates.

**Key settings:**
- Requires Terraform `>= 1.5.0`
- Uses AWS provider `~> 5.0` (latest major version 5)
- Every resource gets tagged automatically with: `ManagedBy=Terraform`, `Project=k8s-lab`, `Environment=lab`

> **💡 Beginner tip:** You never need to edit this file. The region is pulled from `terraform.tfvars` automatically.

---

### `variables.tf` — Declaring Configurable Settings

**What it does:** Defines all the input variables (configurable settings) the project uses — like a list of blank fields on a form. The actual values are filled in by `terraform.tfvars`.

**Variables defined:**

| Variable | Default Value | What It Controls |
|---|---|---|
| `aws_region` | `ap-southeast-1` | Which AWS region to deploy in |
| `project_prefix` | `k8s-lab` | Prefix added to every resource name |
| `ec2_instance_types` | See table in §2 | Which server size each node uses |
| `key_pair_public_path` | `~/.ssh/id_rsa.pub` | Path to your public SSH key |
| `ssh_private_key_path` | `~/.ssh/id_rsa` | Path to your private SSH key |

> **💡 Beginner tip:** Think of `variables.tf` as a form with empty boxes, and `terraform.tfvars` as the filled-in version of that form.

---

### ⭐ `terraform.tfvars` — Your Configuration (Edit This!)

**What it does:** This is the **only file you need to edit** before running Terraform. It provides your real values for all the variables declared in `variables.tf`.

**Current contents and what to change:**

```hcl
aws_region         = "ap-southeast-1"   # Change if you want a different region
project_prefix     = "k8s-lab"          # Change to your project name

# ⬇️ These are updated automatically by setup.sh — or change manually:
key_pair_public_path = "/home/zarif/.ssh/aws5-v7.pub"   # Your public key path
ssh_private_key_path = "/home/zarif/.ssh/aws5-v7.pem"   # Your private key path

ec2_instance_types = {
  Build_Server      = "t2.small"    # Upgrade to t3.small if Jenkins is slow
  Monitoring_Server = "t2.micro"    # Fine for Prometheus + Grafana
  K8S_Master_Node   = "t3.medium"   # Don't go smaller — K8s needs RAM
  K8S_Worker_Node1  = "t3.medium"   # Don't go smaller
  K8S_Worker_Node2  = "t3.medium"   # Don't go smaller
}
```

> ⚠️ **Replace `zarif` with your actual Linux username.** Run `whoami` in your terminal to check.

---

### `vpc.tf` — Creating Your Private Network

**What it does:** Builds an isolated private network in AWS. Think of it as building a private office floor inside a huge shared skyscraper — completely separated from other AWS customers.

**Resources created:**

```
VPC: 10.0.0.0/16 (can hold 65,536 IP addresses)
  │
  ├── Internet Gateway  ← The front door to the internet
  │
  ├── Public Subnet A: 10.0.1.0/24  ← Zone ap-southeast-1a (all 5 servers here)
  ├── Public Subnet B: 10.0.2.0/24  ← Zone ap-southeast-1b (required for ALB)
  │
  └── Route Table: 0.0.0.0/0 → Internet Gateway  ← Routes all traffic to internet
```

> **💡 Why two subnets?** AWS Application Load Balancers require subnets in at least **two different Availability Zones** for high availability. If one data centre has issues, traffic automatically goes to the other.

---

### `ec2.tf` — Creating the 5 Servers

**What it does:** Creates all 5 virtual machines (EC2 instances) in AWS. Uses Terraform's `for_each` to loop over the instance map, so adding a new server is as simple as adding one line to `terraform.tfvars`.

**Every server gets:**
- Latest Ubuntu 22.04 LTS (auto-fetched, always patched)
- Your SSH key imported for access
- A public IP address
- 30 GB of gp3 SSD storage
- Placed in the same security group and subnet

---

### `security_groups.tf` — Firewall Rules

**What it does:** Creates virtual firewalls that control which ports are open on your servers and the load balancer.

**Two security groups are created:**

**`ec2_sg`** — Applied to all 5 servers:

| Port | Protocol | Source | Why It's Open |
|---|---|---|---|
| 22 | TCP | `0.0.0.0/0` | SSH access from anywhere (restrict in production!) |
| 8080 | TCP | `0.0.0.0/0` | Jenkins web UI |
| 3000 | TCP | `0.0.0.0/0` | Grafana dashboard |
| 9090 | TCP | `0.0.0.0/0` | Prometheus metrics |
| 16443 | TCP | `10.0.0.0/16` | MicroK8s API (internal VPC only) |
| 25000 | TCP | `10.0.0.0/16` | MicroK8s cluster join (internal VPC only) |
| All ports | Any | `0.0.0.0/0` | Outbound — lets servers download packages |

**`alb_sg`** — Applied to the Load Balancer:

| Port | Protocol | Source | Why |
|---|---|---|---|
| 80 | TCP | `0.0.0.0/0` | Public HTTP web traffic |

---

### `load_balancer.tf` — Distributing Traffic

**What it does:** Creates an internet-facing Application Load Balancer (ALB) that receives web traffic on port 80 and distributes it across all EC2 instances.

**Components:**
- **Target Group** — The list of servers that receive traffic (health check: `GET /` every 30s)
- **ALB** — Internet-facing, sits across both public subnets for high availability
- **Listener** — Listens on port 80, forwards to the Target Group
- **Attachments** — All 5 EC2 instances are registered as targets on port 80

> **💡 Note:** The ALB routes port 80, but Jenkins/Grafana/Prometheus run on 8080/3000/9090. Access those services directly via their server IPs. To route them through the ALB, you would need to add path-based routing rules.

---

### `s3.tf` — Encrypted Storage Bucket

**What it does:** Creates an S3 bucket for storing the Terraform state file or Jenkins build artifacts.

**Features enabled:**
- **Versioning** — Every change to files is kept, like Git for your data
- **KMS encryption** — All data is encrypted at rest with AWS-managed keys
- **Random suffix** — A random 4-character hex suffix is added to the bucket name to make it globally unique (e.g., `k8s-lab-terraform-state-a1b2c3d4`)

---

### `data.tf` — Reading Existing Information

**What it does:** Uses Terraform "data sources" to read existing information from AWS without creating anything new.

**Two data sources:**
- **`aws_ami.ubuntu`** — Automatically finds the latest Ubuntu 22.04 LTS AMI published by Canonical (Ubuntu's company, account `099720109477`). This ensures you always get the most recently patched OS image.
- **`aws_key_pair.deployer_key`** — Reads your local public key file and imports it to AWS so servers can recognise it during SSH authentication.

> **💡 Why not hardcode the AMI ID?** AMI IDs are different per region and change when Ubuntu releases security patches. Using a data source means you always get the latest one automatically.

---

### `outputs.tf` — What Gets Printed After Deployment

**What it does:** After `terraform apply` completes, Terraform prints important information to your terminal. This file defines what gets printed. The `terraform_run.sh` script also reads these outputs to automatically generate the Ansible inventory file.

**Outputs:**

| Output Name | Example Value | Used For |
|---|---|---|
| `build_server_ip` | `13.212.45.67` | Access Jenkins at `http://<ip>:8080` |
| `monitoring_server_ip` | `54.255.12.34` | Access Grafana / Prometheus |
| `k8s_master_ip` | `18.141.78.90` | SSH into Kubernetes master |
| `k8s_workers_ips` | `[18.139.x.x, 13.250.x.x]` | Worker node IPs |
| `load_balancer_dns` | `k8s-lab-alb-xxxx.ap-southeast-1.elb.amazonaws.com` | ALB public URL |
| `ssh_connection_guide` | `ssh -i ~/.ssh/key.pem ubuntu@<IP>` | Copy-paste SSH template |

---

## 9. Ansible Files — Explained

> **💡 How Ansible works:** Ansible is "agentless" — you don't install anything on the remote servers first. It simply connects over SSH (the same way you'd do manually) and runs commands. You only need Ansible installed on your own machine.

---

### `inventory.ini` — The Server Address Book

**What it does:** Lists every server by group name and IP address so Ansible knows where to connect. This file is **auto-generated by `terraform_run.sh`** — you never edit it manually.

**Example structure after generation:**

```ini
[build]
13.212.45.67

[monitoring]
54.255.12.34

[k8s_master]
18.141.78.90

[k8s_workers]
18.139.11.22
13.250.33.44

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/youruser/.ssh/yourkey.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

---

### `install_services.yml` — The Main Installation Playbook

**What it does:** Connects to each server group and installs the required software. Has 4 "plays" (sections) that target different server groups.

**Play 1 — Install Docker (all servers)**

Runs on: `build`, `monitoring`, `k8s_master`, `k8s_workers`

1. Installs prerequisite packages (`curl`, `gnupg`, `lsb-release`, etc.)
2. Adds Docker's official GPG security key
3. Adds Docker's official package repository
4. Installs Docker CE + CLI + containerd + compose plugin
5. Starts Docker service and enables it to auto-start on reboot
6. Adds the `ubuntu` user to the `docker` group (so it can run `docker` without `sudo`)
7. Copies the `Dockerfile.jenkins`, `Dockerfile.grafana`, `plugins.txt`, `datasources.yml` to `/tmp/docker-tools/`

**Play 2 — Configure Jenkins (Build_Server only)**

1. Builds the custom Jenkins Docker image from `Dockerfile.jenkins`
2. Starts the Jenkins container: ports `8080` (UI) and `50000` (agent connections)
3. Mounts `/var/run/docker.sock` so Jenkins pipelines can build Docker images
4. Mounts a `jenkins_home` Docker volume so Jenkins data survives restarts
5. Sets `JAVA_OPTS=-Djenkins.install.runSetupWizard=false` to skip the initial setup wizard

**Play 3 — Configure Monitoring (Monitoring_Server only)**

1. Creates `/etc/prometheus/` config directory
2. Writes a basic `prometheus.yml` config (scrapes itself on `localhost:9090`)
3. Starts Prometheus container: port `9090`, data volume `prometheus_data`
4. Builds the custom Grafana Docker image from `Dockerfile.grafana`
5. Starts Grafana container: port `3000`, credentials `admin`/`admin123`

**Play 4 — Install MicroK8s (k8s_master + k8s_workers)**

1. Installs `microk8s` via the `snap` package manager (classic confinement)
2. Waits up to 100 seconds for MicroK8s to become ready
3. Adds `ubuntu` user to the `microk8s` group
4. On master only: enables add-ons: `dns`, `registry`, `metrics-server`

---

### `join_cluster.yml` — Forming the Kubernetes Cluster

**What it does:** After `install_services.yml` installs MicroK8s on all K8s nodes separately, this playbook connects them into a single cluster. Must be run after `install_services.yml`.

**Play 1 — Master Node setup:**

1. Verifies MicroK8s is installed and waits for it to be ready
2. Adds `ubuntu` user to `microk8s` group
3. Runs `microk8s add-node --token-ttl 3600` to generate a one-hour join token
4. Extracts the connection string from the output (looks like `IP:PORT/TOKEN`)
5. Labels the master node with `role=master`

**Play 2 — Worker Nodes join:**

1. Waits 15 seconds for the master's token to be ready
2. Runs `microk8s join <connection_string> --worker` on each worker
3. Labels each worker node with `role=worker`

---

### `cleanup.yml` — Removing Everything

**What it does:** Stops and removes all Docker containers and MicroK8s. Used before destroying infrastructure to ensure a clean teardown.

- Stops and removes: `jenkins`, `grafana`, `prometheus` containers
- Removes Docker volumes: `jenkins_home`, `prometheus_data`
- Removes MicroK8s via `snap remove microk8s --purge`

---

### `tools/Dockerfile.jenkins` — Custom Jenkins Image

**What it does:** Builds a customised Jenkins image on top of the official `jenkins/jenkins:lts-jdk17` base image.

**Extra features added:**
- Docker CLI installed inside the container (so Jenkins pipelines can run `docker build`)
- Pre-installs these plugins automatically via `plugins.txt`:

| Plugin | Purpose |
|---|---|
| `workflow-aggregator` | Pipeline / Jenkinsfile support |
| `git` | Clone Git repositories |
| `github-branch-source` | Build from GitHub PRs and branches |
| `docker-plugin` + `docker-workflow` | Run build agents as Docker containers |
| `kubernetes` + `kubernetes-cli` | Run build agents as Kubernetes pods |
| `configuration-as-code` | Configure Jenkins via YAML (JCasC) |
| `blueocean` | Modern pipeline UI |
| `timestamper` | Adds timestamps to build logs |

---

### `tools/Dockerfile.grafana` — Custom Grafana Image

**What it does:** Builds a customised Grafana image that comes pre-connected to Prometheus — so you don't need to manually configure the data source after first login.

**Customisation:** Copies `datasources.yml` into `/etc/grafana/provisioning/datasources/` so Grafana automatically connects to Prometheus at `http://localhost:9090` on startup.

---

### `tools/datasources.yml` — Grafana → Prometheus Connection

**What it does:** Grafana provisioning file that pre-configures Prometheus as the default data source. Uses `access: proxy` (Grafana fetches data server-side, not from your browser).

---

## 10. Automation Scripts — Explained

### `setup.sh` — Main Entry Point ⭐

**Run this first.** Interactive bootstrap script that does everything in sequence:

**Phase 1 — AWS CLI Setup:**
- Checks if AWS CLI v2 is installed, installs or updates it if needed
- Loads credentials from `.env` if it exists
- Prompts you to reuse or replace credentials
- Saves credentials to `.env` and configures `~/.aws/credentials`
- Verifies credentials work by calling `aws sts get-caller-identity`

**Phase 2 — SSH Key Setup:**
- Lists SSH keys in your AWS account and locally in `~/.ssh/`
- Shows keys that exist in **both** places (ready to use)
- Option `[1]`: Use existing key — sets permissions to `400`
- Option `[2]`: Create new key — calls `aws ec2 create-key-pair`, saves `.pem`, generates `.pub`

**Phase 3 — tfvars Update:**
- Automatically patches `key_pair_public_path` and `ssh_private_key_path` in `terraform.tfvars` with the selected key paths

**Phase 4 — Main Menu:**

```
[1] 🚀 Run Terraform   → Provisions AWS infra + generates Ansible inventory
[2] 🤖 Run Ansible     → Re-configures existing servers (requires inventory.ini)
[3] 🗑️  Clean Up        → Destroys everything in AWS (irreversible!)
[h] 📚 Help
[q] ❌ Quit
```

---

### `terraform/terraform_run.sh` — Terraform Orchestrator

**What it does:** Handles the full Terraform lifecycle and generates the Ansible inventory.

**Steps executed:**
1. Loads `.env` credentials
2. Installs `jq` if missing (needed for JSON output parsing)
3. Checks if Terraform is installed — if version is outdated, auto-downloads the latest binary from HashiCorp
4. Runs `terraform init` (downloads the AWS provider plugin)
5. Runs `terraform plan -out=tfplan` (previews changes)
6. Runs `terraform apply -auto-approve tfplan` (creates resources)
7. Reads all Terraform outputs as JSON
8. Resolves the SSH key path from `terraform.tfvars` or environment variable
9. Generates `ansible/inventory.ini` with all real server IPs

---

### `ansible/ansible_run.sh` — Ansible Orchestrator

**What it does:** Runs all Ansible playbooks in the correct order.

**Steps executed:**
1. Checks if Ansible is installed — if version is outdated, auto-upgrades via pip
2. Installs Ansible on fresh systems (handles Ubuntu's "externally managed environment" restriction)
3. **Step 1:** Runs `install_services.yml` limited to `build,monitoring` — installs Docker, Jenkins, Prometheus, Grafana
4. **Step 2:** Runs `install_services.yml` limited to `k8s_master,k8s_workers` — installs MicroK8s
5. **Step 3:** Runs `join_cluster.yml` — forms the Kubernetes cluster
6. **Step 4:** SSHes into the master node and labels workers as `worker1`, `worker2`
7. Prints all service URLs at the end

---

### `terraform/terraform_destroy.sh` — Clean Destruction

**What it does:** Safely tears down all AWS resources and cleans up local files.

```bash
./terraform/terraform_destroy.sh
```

**Actions taken:**
1. Loads `.env` credentials
2. Runs `terraform destroy -auto-approve` (deletes all AWS resources)
3. Removes `.terraform/` directory (downloaded plugins)
4. Removes `terraform.tfstate*` files (local state)
5. Removes `*.tfplan` / `tfplan` files (stale plans)
6. Removes `ansible/inventory.ini` (now stale — IPs no longer exist)
7. Preserves `.terraform.lock.hcl` (keeps provider version pinned for next deploy)

---

### `terraform/validate_credentials.sh` — Credential Check

**What it does:** Quick sanity check to verify your AWS credentials are valid before running anything.

```bash
./terraform/validate_credentials.sh
```

Checks that `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` are all set, then calls `aws sts get-caller-identity` to confirm they actually work against the AWS API.

---

### `terraform/aws_god_mode_cleanup.sh` — ⚠️ Nuclear Option

> **⚠️ EXTREMELY DESTRUCTIVE — This deletes EVERYTHING in your AWS account in the configured region, not just resources created by this project.**

Only use this if `terraform destroy` fails due to state corruption and you need a last resort.

```bash
# You must type "DESTROY" to proceed — there is no undo
./terraform/aws_god_mode_cleanup.sh
```

Runs `terraform_destroy.sh` first, then runs `aws-nuke` to wipe any remaining resources.

---

## 11. Configuration Reference

### All Variables at a Glance

| Variable | File | Default | Description |
|---|---|---|---|
| `aws_region` | `terraform.tfvars` | `ap-southeast-1` | AWS region (Singapore) |
| `project_prefix` | `terraform.tfvars` | `k8s-lab` | Name prefix for all resources |
| `key_pair_public_path` | `terraform.tfvars` | auto-set by `setup.sh` | Your SSH public key path |
| `ssh_private_key_path` | `terraform.tfvars` | auto-set by `setup.sh` | Your SSH private key path |
| `Build_Server` instance | `terraform.tfvars` | `t2.small` | Jenkins server size |
| `Monitoring_Server` instance | `terraform.tfvars` | `t2.micro` | Monitoring server size |
| `K8S_Master_Node` instance | `terraform.tfvars` | `t3.medium` | Kubernetes master size |
| `K8S_Worker_Node1/2` instance | `terraform.tfvars` | `t3.medium` | Kubernetes worker size |

### Environment Variables (`.env` file)

```bash
AWS_ACCESS_KEY_ID=AKIA...           # Your AWS access key
AWS_SECRET_ACCESS_KEY=...           # Your AWS secret key
AWS_DEFAULT_REGION=ap-southeast-1   # Target region
AWS_DEFAULT_OUTPUT=json             # CLI output format
```

> ⚠️ **Never commit `.env` to Git.** It is already in `.gitignore`.

---

## 12. Accessing Your Services After Deployment

After deployment, all IPs are printed by `ansible_run.sh`. You can also get them by running:

```bash
cd terraform/
terraform output
```

### Jenkins — CI/CD Pipelines

```
URL:  http://<BUILD_SERVER_IP>:8080
User: admin
Pass: Auto-generated — retrieve it with:
      docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Grafana — Monitoring Dashboards

```
URL:  http://<MONITORING_SERVER_IP>:3000
User: admin
Pass: admin123
```
Prometheus is already pre-configured as the default data source. Go to **Dashboards → New → Import** and search for dashboard ID `1860` (Node Exporter Full) to get CPU/RAM/disk charts.

### Prometheus — Raw Metrics

```
URL: http://<MONITORING_SERVER_IP>:9090
```
No login required. Go to **Status → Targets** to see what's being monitored.

### Kubernetes — SSH into Master

```bash
ssh -i ~/.ssh/yourkey.pem ubuntu@<K8S_MASTER_IP>

# Then on the master:
microk8s kubectl get nodes -L role     # See all nodes and their roles
microk8s kubectl get pods -A           # See all running pods
microk8s kubectl get svc -A            # See all services
```

### Application Load Balancer

```
URL: http://<load_balancer_dns>
```
Routes HTTP port 80 traffic across all EC2 instances. Useful for hosting a web application on the K8s worker nodes.

---

## 13. Destroying Everything (Clean Up)

AWS charges by the hour. Always destroy resources when you're done experimenting.

### Option A — Via setup.sh menu (recommended)

```bash
./setup.sh
# Choose [3] — Clean Up
# Type: DESTROY
```

### Option B — Direct script

```bash
./terraform/terraform_destroy.sh
```

### What gets deleted

| Deleted | Preserved |
|---|---|
| All 5 EC2 instances | `.env` (your credentials) |
| VPC, subnets, routes | SSH key files on your machine |
| Security groups | `terraform.tfvars` |
| Application Load Balancer | `.terraform.lock.hcl` |
| S3 bucket | |
| SSH key pair in AWS | |
| All Terraform state files | |
| `ansible/inventory.ini` | |

> **💡 Tip:** You can redeploy from scratch with `./setup.sh → [1]` after destroying.

---

## 14. Troubleshooting Common Issues

### ❌ "SSH Key not found"

```
❌ SSH Key not found: /home/youruser/.ssh/aws5-v7.pem
```

**Fix:** Open `terraform/terraform.tfvars` and update `ssh_private_key_path` to the correct path of your `.pem` file.

---

### ❌ "Error: No valid credential sources found"

```
Error: No valid credential sources found for AWS Provider
```

**Fix:** Run `./terraform/validate_credentials.sh` to check your `.env` file. Make sure `.env` is in the project root and contains valid keys.

---

### ❌ Ansible "UNREACHABLE" error

```
fatal: [13.212.x.x]: UNREACHABLE! => {"msg": "Failed to connect to the host via ssh"}
```

**Fix:** The server may still be booting. Wait 60–90 seconds and re-run `./setup.sh → [2]`. Also check that port 22 is open in your security group.

---

### ❌ "Error creating S3 bucket: BucketAlreadyExists"

```
Error: creating S3 Bucket: BucketAlreadyOwnedByYou
```

**Fix:** A bucket with that name already exists. Change `project_prefix` in `terraform.tfvars` to something unique (e.g., add your name: `k8s-lab-alice`).

---

### ❌ MicroK8s workers not joining the cluster

**Fix:** SSH into the master and run:

```bash
ssh -i ~/.ssh/yourkey.pem ubuntu@<MASTER_IP>
microk8s add-node       # Generate a new join token
# Then SSH into the worker and run the displayed join command
```

---

### ❌ Jenkins shows a blank page or won't load

**Fix:** Jenkins takes 2–3 minutes to fully start. Wait, then check:

```bash
ssh -i ~/.ssh/yourkey.pem ubuntu@<BUILD_IP>
docker logs jenkins --tail 50
```

---

### ❌ Grafana shows "Data source not found"

**Fix:** Prometheus and Grafana are on the same server but Grafana's datasource is configured with `url: http://localhost:9090`. If this doesn't work, update the datasource URL inside Grafana: **Configuration → Data Sources → Prometheus → URL** → set to `http://prometheus:9090`.

---

## 15. Security Notes

### ⚠️ Before Pushing to Git — Always Check

```bash
git status                  # Review what's staged
git add -n .                # Dry-run: see what would be committed
```

**Things that must NEVER be committed:**

| File / Pattern | Why |
|---|---|
| `.env` | Contains AWS access keys |
| `*.pem`, `*.key` | Private SSH keys give server access |
| `terraform.tfstate` | Contains infrastructure details and sometimes secrets |
| `ansible/inventory.ini` | Contains your server's real IP addresses |

All of these are already covered by `.gitignore`.

---

### ⚠️ Production Hardening Checklist

This project is configured for a **lab/learning environment**. Before using in production:

- [ ] **Restrict SSH (port 22)** — Change `cidr_blocks = ["0.0.0.0/0"]` in `security_groups.tf` to your specific IP
- [ ] **Change Grafana password** — Default is `admin123`. Change it immediately after first login
- [ ] **Enable HTTPS** — Add an SSL certificate to the ALB and redirect port 80 → 443
- [ ] **Use IAM roles** instead of static access keys for EC2 instances
- [ ] **Enable VPC Flow Logs** — Monitor all network traffic
- [ ] **Move servers to private subnets** — Access via a bastion host or VPN instead of public IPs
- [ ] **Rotate AWS credentials** if they have ever been accidentally exposed or committed

---

### 🔐 If You Accidentally Expose Credentials

If AWS keys are ever committed to Git or shared publicly:

1. **Immediately deactivate the key** — AWS Console → IAM → Users → Security Credentials → Deactivate
2. **Delete the old key** and create a new one
3. **Check CloudTrail** for unauthorized usage (AWS Console → CloudTrail → Event History)
4. **Remove from Git history** using `git filter-branch` or the BFG Repo Cleaner tool
5. **Force push** the cleaned history: `git push --force-with-lease`

---

## License

Add a `LICENSE` file if you intend to distribute this project.

---

*Documentation version: 2.0 — Covers all files in aws-k8s-infra-v2*