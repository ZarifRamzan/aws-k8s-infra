# ==============================================================================
# terraform.tfvars - Overrides variables with project-specific values
# ==============================================================================

aws_region         = "ap-southeast-1"
project_prefix     = "k8s-lab"
# ✅ Replace 'zarif' with your actual username (run 'whoami' to check)
key_pair_public_path = "/home/zarif/.ssh/aws5-v7.pub"
ssh_private_key_path = "/home/zarif/.ssh/aws5-v7.pem"


# Optional: Override instance types if needed
ec2_instance_types = {
  Build_Server      = "t2.small"
  Monitoring_Server = "t2.micro"
  K8S_Master_Node   = "t3.medium"
  K8S_Worker_Node1  = "t3.medium"
  K8S_Worker_Node2  = "t3.medium"
}