# ==============================================================================
# data.tf - Fetches dynamic data like latest Ubuntu AMI and SSH Key Pair
# - Avoids hardcoding AMI IDs (which change per region)
# ==============================================================================

# Fetch latest Ubuntu 22.04 LTS AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Read local public SSH key for AWS Key Pair import
resource "aws_key_pair" "deployer_key" {
  key_name   = "${var.project_prefix}-key"
  public_key = file(var.key_pair_public_path)
  
  # Tags for easy tracking
  tags = {
    Name = "${var.project_prefix}-deployer-key"
  }
}