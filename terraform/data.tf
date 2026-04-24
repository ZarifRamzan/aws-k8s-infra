# ============================================================
# data.tf
# ------------------------------------------------------------
# PURPOSE:
#   "Data sources" let Terraform READ information from AWS
#   without creating anything. This file fetches:
#
#     1. The latest Ubuntu 22.04 LTS AMI (disk image)
#     2. The list of Availability Zones in the region
#
# WHY NOT JUST HARDCODE AN AMI ID?
#   AMI IDs look like "ami-0abcdef1234567890" and they:
#     - Are DIFFERENT per AWS region
#     - Get REPLACED when Ubuntu releases security patches
#     - Become outdated quickly
#
#   Using a data source means Terraform asks AWS:
#   "What is the LATEST Ubuntu 22.04 image right now?"
#   → You always get an up-to-date, patched image automatically.
#
# HOW TO USE THE RESULT:
#   Reference it anywhere in your .tf files as:
#     data.aws_ami.ubuntu.id
#   For example, in ec2.tf:
#     ami = data.aws_ami.ubuntu.id
# ============================================================


# -------------------------------------------------------
# Fetch the latest official Ubuntu 22.04 LTS AMI
# -------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true   # If multiple matches found, take the newest one

  # Filter 1: Image name must match Ubuntu 22.04 LTS (Jammy Jellyfish) pattern
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    # The * at the end is a wildcard — matches any date suffix
    # e.g. "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240101"
  }

  # Filter 2: Must use HVM (Hardware Virtual Machine) virtualisation
  # This is required for modern instance types like t2 and t3
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Only trust images published by Canonical (Ubuntu's company)
  # Their official AWS account ID is 099720109477
  # This prevents accidentally using a fake or malicious image
  owners = ["099720109477"]
}


# -------------------------------------------------------
# Fetch available Availability Zones in the region
# -------------------------------------------------------
# Availability Zones = separate physical data centres within one region.
# Singapore (ap-southeast-1) has three: 1a, 1b, 1c.
# We declare this data source so we can reference AZ info if needed.
data "aws_availability_zones" "available" {
  state = "available"   # Only return zones that are currently open and usable
}
