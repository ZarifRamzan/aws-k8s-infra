# ============================================================
# s3.tf
# ------------------------------------------------------------
# PURPOSE:
#   This file WOULD create the S3 bucket and DynamoDB table
#   needed for Terraform remote state storage.
#
# !! CURRENTLY DISABLED !!
#   All resources in this file are commented out.
#   The project is using LOCAL backend (state stored on your
#   machine in terraform/terraform.tfstate).
#
# WHY KEEP THIS FILE?
#   So you can easily enable remote state in the future
#   by simply uncommenting the blocks below and updating
#   the backend in provider.tf.
#
# WHEN SHOULD YOU ENABLE THIS?
#   Enable S3 remote state when:
#     ✅ You work with a team (shared state)
#     ✅ You want state backed up safely in the cloud
#     ✅ You want to prevent two people applying at the same time
#
# HOW TO ENABLE (step-by-step):
#   Step 1 → Uncomment all resource blocks below
#   Step 2 → Set s3_bucket_name in terraform.tfvars
#   Step 3 → Run: terraform apply   (creates the bucket)
#   Step 4 → In provider.tf, comment out "backend local" block
#   Step 5 → In provider.tf, uncomment the "backend s3" block
#   Step 6 → Run: terraform init -reconfigure
#   Step 7 → When prompted "copy state to S3?", type: yes
# ============================================================


# -------------------------------------------------------
# S3 Bucket for Terraform State — DISABLED
# -------------------------------------------------------
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = var.s3_bucket_name   # Must be globally unique across ALL AWS accounts
#
#   # Prevent accidental deletion of state history
#   lifecycle {
#     prevent_destroy = true   # Terraform will refuse to destroy this bucket
#   }
#
#   tags = {
#     Name        = "${var.project_name}-tfstate"
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }


# -------------------------------------------------------
# Enable Versioning on the State Bucket — DISABLED
# -------------------------------------------------------
# Versioning keeps old copies of state.
# If your state gets corrupted, you can restore a previous version.
#
# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   versioning_configuration {
#     status = "Enabled"
#   }
# }


# -------------------------------------------------------
# Enable Encryption on the State Bucket — DISABLED
# -------------------------------------------------------
# State files can contain IP addresses and resource IDs.
# Encryption ensures this data is protected at rest.
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }


# -------------------------------------------------------
# Block Public Access on the State Bucket — DISABLED
# -------------------------------------------------------
# State files should NEVER be publicly readable.
# This block ensures no public access policy can override that.
#
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }


# -------------------------------------------------------
# DynamoDB Table for State Locking — DISABLED
# -------------------------------------------------------
# When two people run `terraform apply` simultaneously,
# one will get a "lock error" and must wait.
# This prevents race conditions that corrupt the state file.
#
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "terraform-state-lock"
#   billing_mode = "PAY_PER_REQUEST"   # Only pay when the table is actually used
#   hash_key     = "LockID"
#
#   attribute {
#     name = "LockID"
#     type = "S"   # S = String data type
#   }
#
#   tags = {
#     Name        = "${var.project_name}-tfstate-lock"
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }
