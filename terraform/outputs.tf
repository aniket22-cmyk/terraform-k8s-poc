output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k8s_node.public_ip
}

