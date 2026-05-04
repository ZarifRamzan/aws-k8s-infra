# ==============================================================================
# variables.tf - Defines input variables for flexibility & reusability
# ==============================================================================

variable "aws_region" {
  description = "AWS region for infrastructure deployment. Default is Singapore."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_prefix" {
  description = "Prefix added to all resource names to avoid collisions in shared accounts"
  type        = string
  default     = "k8s-lab"
}

variable "ec2_instance_types" {
  description = "Map of instance names to their EC2 instance types"
  type        = map(string)
  default = {
    Build_Server     = "t2.small"
    Monitoring_Server= "t2.micro"
    K8S_Master_Node  = "t3.medium"
    K8S_Worker_Node1 = "t3.medium"
    K8S_Worker_Node2 = "t3.medium"
  }
}

variable "key_pair_public_path" {
  description = "Path to your public SSH key to upload to AWS"
  type        = string
  default     = "/home/$USER/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to your private SSH key for Ansible connectivity"
  type        = string
  default     = "/home/$USER/.ssh/id_rsa"
}