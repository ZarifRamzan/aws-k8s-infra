# ==============================================================================
# ec2.tf - Provisions 5 EC2 instances with public IPs
# - Uses dynamic mapping for instance types
# - Waits for cloud-init completion
# ==============================================================================

resource "aws_instance" "this" {
  for_each = var.ec2_instance_types

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = each.value
  key_name               = aws_key_pair.deployer_key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_prefix}-${each.key}"
    Role = each.key
  }

  # Ensures Terraform waits until instance is reachable via SSH
  user_data = <<-EOF
              #!/bin/bash
              echo "Cloud-init starting..."
              sudo apt update
              sudo apt install -y curl wget
              systemctl enable ssh
              EOF

  lifecycle {
    ignore_changes = [ami, user_data] # Prevents recreation on AMI updates
  }
}