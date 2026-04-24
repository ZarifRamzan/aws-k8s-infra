# ============================================================
# security_groups.tf
# ------------------------------------------------------------
# PURPOSE:
#   Security Groups are AWS virtual firewall rules.
#   Each group has two sets of rules:
#     - ingress = incoming traffic (what is ALLOWED IN)
#     - egress  = outgoing traffic (what is ALLOWED OUT)
#
# THIS FILE CREATES 4 SECURITY GROUPS:
#   1. build      - for Build_Server (Jenkins)
#   2. monitoring - for Monitoring_Server (Prometheus + Grafana)
#   3. k8s        - for all 3 Kubernetes nodes
#   4. alb        - for the Application Load Balancer
#
# PORT REFERENCE:
#   Port 22          = SSH (remote terminal login)
#   Port 80          = HTTP (regular web traffic)
#   Port 443         = HTTPS (secure web traffic)
#   Port 3000        = Grafana web UI
#   Port 8080        = Jenkins web UI
#   Port 9090        = Prometheus web UI
#   Port 9100        = Node Exporter (host metrics)
#   Port 10443       = Kubernetes Dashboard
#   Port 16443       = Kubernetes API server (microk8s)
#   Port 30000-32767 = Kubernetes NodePort range
#
# CIDR NOTE:
#   0.0.0.0/0    = open to the entire internet (use carefully)
#   var.vpc_cidr = only reachable from inside our private VPC
# ============================================================


# -------------------------------------------------------
# 1. Build Server Security Group
#    Attached to: Build_Server (runs Jenkins via Docker)
# -------------------------------------------------------
resource "aws_security_group" "build" {
  name        = "${var.project_name}-build-sg"
  description = "Firewall rules for Build Server running Jenkins"
  vpc_id      = aws_vpc.main.id

  # ---- INGRESS (incoming traffic) ----

  # Allow SSH so you can log into the server remotely
  # In production, replace 0.0.0.0/0 with your specific IP
  ingress {
    description = "SSH remote terminal access on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to the Jenkins web dashboard
  ingress {
    description = "Jenkins Web UI on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Jenkins build agents to connect back to the master
  ingress {
    description = "Jenkins JNLP agent communication on port 50000"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- EGRESS (outgoing traffic) ----

  # Allow all outbound so the server can pull Docker images,
  # download packages, clone git repos, reach AWS APIs, etc.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-build-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 2. Monitoring Server Security Group
#    Attached to: Monitoring_Server (Prometheus + Grafana)
# -------------------------------------------------------
resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-monitoring-sg"
  description = "Firewall rules for Monitoring Server running Prometheus and Grafana"
  vpc_id      = aws_vpc.main.id

  # ---- INGRESS (incoming traffic) ----

  # Allow SSH login to the monitoring server
  ingress {
    description = "SSH remote terminal access on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to the Grafana dashboard UI
  ingress {
    description = "Grafana Web UI on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access to the Prometheus UI and query API
  ingress {
    description = "Prometheus Web UI on port 9090"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Prometheus to scrape Node Exporter metrics from all servers
  # Restricted to internal VPC traffic only - no public access needed
  ingress {
    description = "Node Exporter metrics port 9100 internal VPC only"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # ---- EGRESS (outgoing traffic) ----

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-monitoring-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 3. Kubernetes Nodes Security Group
#    Attached to: K8S_Master_Node, K8S_Worker_Node1, K8S_Worker_Node2
#    All 3 nodes share one group - they all need the same ports
# -------------------------------------------------------
resource "aws_security_group" "k8s" {
  name        = "${var.project_name}-k8s-sg"
  description = "Firewall rules for all Kubernetes nodes master and workers"
  vpc_id      = aws_vpc.main.id

  # ---- INGRESS (incoming traffic) ----

  # Allow SSH login to any Kubernetes node
  ingress {
    description = "SSH remote terminal access on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API server - kubectl and worker nodes talk to master here
  # microk8s uses port 16443 instead of the standard 6443
  ingress {
    description = "Kubernetes API server on port 16443"
    from_port   = 16443
    to_port     = 16443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes Dashboard web UI (enabled via microk8s addon)
  ingress {
    description = "Kubernetes Dashboard on port 10443"
    from_port   = 10443
    to_port     = 10443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ALL traffic between nodes inside the VPC
  # Nodes need unrestricted internal communication for:
  #   - pod-to-pod networking
  #   - health checks
  #   - service discovery
  #   - cluster join handshake (port 25000)
  ingress {
    description = "All internal node-to-node traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # NodePort range - apps deployed in Kubernetes can be exposed
  # on a port in this range so external users can reach them directly
  ingress {
    description = "Kubernetes NodePort service range 30000 to 32767"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- EGRESS (outgoing traffic) ----

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-k8s-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}


# -------------------------------------------------------
# 4. Application Load Balancer Security Group
#    Attached to: the ALB defined in outputs.tf
#    The ALB is the single public entry point for all traffic
# -------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Firewall rules for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # ---- INGRESS (incoming traffic) ----

  # Accept HTTP traffic from anyone on the internet
  # The ALB listener routes this to Jenkins or Grafana
  ingress {
    description = "HTTP traffic from the internet on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Accept HTTPS traffic - requires an SSL certificate in ACM
  ingress {
    description = "HTTPS traffic from the internet on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ---- EGRESS (outgoing traffic) ----

  # Allow the ALB to forward requests to any backend EC2 instance
  egress {
    description = "Forward traffic to backend EC2 instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}