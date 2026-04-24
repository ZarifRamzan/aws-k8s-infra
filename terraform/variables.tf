# ============================================================
# variables.tf
# ------------------------------------------------------------
# PURPOSE:
#   Declares every configurable setting in this project.
#   Set your actual values in terraform.tfvars.
# ============================================================

variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "IP address range for the entire VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP range for public subnet 1 in ap-southeast-1a. All EC2 instances go here."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "IP range for public subnet 2 in ap-southeast-1b. Required by the ALB."
  type        = string
  default     = "10.0.2.0/24"
}

variable "key_name" {
  description = "Name of the AWS EC2 Key Pair for SSH access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Full local path to your .pem private key file"
  type        = string
  default     = "~/.ssh/id_rsa.pem"
}

variable "instance_type_build" {
  description = "EC2 size for Build_Server running Jenkins"
  type        = string
  default     = "t2.small"
}

variable "instance_type_monitoring" {
  description = "EC2 size for Monitoring_Server running Prometheus and Grafana"
  type        = string
  default     = "t2.micro"
}

variable "instance_type_k8s" {
  description = "EC2 size for all Kubernetes nodes. Minimum t3.medium for microk8s."
  type        = string
  default     = "t3.medium"
}

variable "s3_bucket_name" {
  description = "Future S3 bucket name for Terraform remote state. Disabled for now."
  type        = string
  default     = "DISABLED"
}

variable "project_name" {
  description = "Label applied to every AWS resource for easy identification"
  type        = string
  default     = "aws-k8s-infra"
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod"
  type        = string
  default     = "dev"
}
