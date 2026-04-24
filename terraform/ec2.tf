# ============================================================
# ec2.tf
# ------------------------------------------------------------
# This file creates the "Lock" in AWS and the 5 Virtual Machines.
# ============================================================

# 1. REGISTER THE KEY PAIR
# This takes your local public key and uploads it to AWS Singapore.
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("${var.ssh_private_key_path}.pub")
}

# -------------------------------------------------------
# 2. Build Server (Jenkins)
# -------------------------------------------------------
resource "aws_instance" "build_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_build
  subnet_id     = aws_subnet.public_1.id
  
  # Uses the key we registered above
  key_name      = aws_key_pair.deployer.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.build.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "Build_Server"
    Role        = "build"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------
# 3. Monitoring Server (Prometheus + Grafana)
# -------------------------------------------------------
resource "aws_instance" "monitoring_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_monitoring
  subnet_id     = aws_subnet.public_1.id
  key_name      = aws_key_pair.deployer.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.monitoring.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "Monitoring_Server"
    Role        = "monitoring"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------
# 4. Kubernetes Master Node
# -------------------------------------------------------
resource "aws_instance" "k8s_master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_k8s
  subnet_id     = aws_subnet.public_1.id
  key_name      = aws_key_pair.deployer.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8s.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "K8S_Master_Node"
    Role        = "k8s-master"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------
# 5. Kubernetes Worker Node 1
# -------------------------------------------------------
resource "aws_instance" "k8s_worker1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_k8s
  subnet_id     = aws_subnet.public_1.id
  key_name      = aws_key_pair.deployer.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8s.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "K8S_Worker_Node1"
    Role        = "k8s-worker"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------
# 6. Kubernetes Worker Node 2
# -------------------------------------------------------
resource "aws_instance" "k8s_worker2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_k8s
  subnet_id     = aws_subnet.public_1.id
  key_name      = aws_key_pair.deployer.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8s.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "K8S_Worker_Node2"
    Role        = "k8s-worker"
    Project     = var.project_name
    Environment = var.environment
  }
}