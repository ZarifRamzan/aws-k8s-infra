# ==============================================================================
# outputs.tf - Exposes critical information for Ansible & User Reference
# - Used by terraform_run.sh to generate Ansible inventory
# ==============================================================================

output "build_server_ip" {
  description = "Public IP of Jenkins Build Server"
  value       = aws_instance.this["Build_Server"].public_ip
}

output "monitoring_server_ip" {
  description = "Public IP of Prometheus/Grafana Server"
  value       = aws_instance.this["Monitoring_Server"].public_ip
}

output "k8s_master_ip" {
  description = "Public IP of Kubernetes Master"
  value       = aws_instance.this["K8S_Master_Node"].public_ip
}

output "k8s_workers_ips" {
  description = "List of Worker Node IPs"
  value       = [
    aws_instance.this["K8S_Worker_Node1"].public_ip,
    aws_instance.this["K8S_Worker_Node2"].public_ip
  ]
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ssh_connection_guide" {
  description = "Command template for SSH access"
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@<IP>"
}