output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k8s_node.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.k8s_node.id
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.k8s_node.public_ip}:30001"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i your-key.pem ubuntu@${aws_instance.k8s_node.public_ip}"
}

output "setup_status" {
  description = "Setup instructions"
  value       = "Wait 5-10 minutes for deployment to complete, then visit: http://${aws_instance.k8s_node.public_ip}:30001"
}