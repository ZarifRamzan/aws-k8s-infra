# ============================================================
# provider.tf
# ------------------------------------------------------------
# PURPOSE:
#   Tells Terraform WHICH cloud provider to use and WHERE.
#   Think of this as telling Terraform:
#   "Go talk to AWS, and work in the Singapore region."
#
# WHY THIS FILE EXISTS:
#   Terraform supports many clouds (AWS, Azure, GCP, etc.).
#   This file locks us to AWS + Singapore (ap-southeast-1)
#   so every resource we create lands in the right place.
#
# BACKEND (LOCAL):
#   The state file (terraform.tfstate) will be saved on YOUR
#   local machine in the terraform/ folder.
#   This is the simplest setup — no S3 bucket needed.
#
#   ⚠️  NOTE: S3 remote backend is TEMPORARILY DISABLED.
#   When you are ready to enable it, see the commented-out
#   backend block at the bottom of this file.
# ============================================================

terraform {
  # Minimum Terraform CLI version required to run this project
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Official AWS provider from HashiCorp
      version = "~> 5.0"         # Use any 5.x version (stable and modern)
    }
  }

  # ----------------------------------------------------------
  # LOCAL BACKEND (active)
  # ----------------------------------------------------------
  # Terraform state is stored in a local file called
  # terraform.tfstate inside your terraform/ directory.
  # Simple, no extra AWS resources needed.
  # ----------------------------------------------------------
  backend "local" {
    path = "terraform.tfstate"   # State file lives right here in terraform/
  }

  # ----------------------------------------------------------
  # S3 REMOTE BACKEND (disabled — uncomment when ready)
  # ----------------------------------------------------------
  # Storing state in S3 allows teams to share state and
  # prevents conflicts when multiple people run Terraform.
  # To enable:
  #   1. Create your S3 bucket manually or via the AWS Console
  #   2. Create a DynamoDB table named "terraform-state-lock"
  #   3. Uncomment the block below and comment out "backend local" above
  # ----------------------------------------------------------
  # backend "s3" {
  #   bucket         = "YOUR_BUCKET_NAME_HERE"
  #   key            = "aws-k8s-infra/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# ---------------------------------------------------------------
# AWS Provider Configuration
# ---------------------------------------------------------------
# This tells the AWS provider which region to work in.
# var.aws_region is defined in variables.tf and defaults to
# "ap-southeast-1" (Singapore).
# ---------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}
