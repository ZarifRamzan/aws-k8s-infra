# ==============================================================================
# s3.tf - Creates an S3 bucket for Terraform state backup or build artifacts
# - Can be used later as a remote state backend or Jenkins artifact storage
# ==============================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_prefix}-terraform-state-${random_id.suffix.hex}"

  tags = {
    Name = "${var.project_prefix}-state-bucket"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}