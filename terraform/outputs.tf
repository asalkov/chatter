output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.chatter.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.chatter.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.chatter.public_dns
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = aws_eip.chatter.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${aws_eip.chatter.public_ip}"
}

output "application_url" {
  description = "Application URL"
  value       = var.create_dns ? "https://${var.domain_name}" : "http://${aws_eip.chatter.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.chatter.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    public_1 = aws_subnet.public_1.id
    public_2 = aws_subnet.public_2.id
  }
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "http://${aws_eip.chatter.public_ip}/health"
}
