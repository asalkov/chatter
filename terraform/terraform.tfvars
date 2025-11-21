# terraform.tfvars.example
# Copy to terraform.tfvars and fill in your values

aws_region   = "us-east-1"
environment  = "production"
project_name = "chatter"

# Compute
instance_type = "t3.micro"
volume_size   = 20

# SSH key pair name (create with: aws ec2 create-key-pair --key-name chatter-key)
ssh_key_name = "chatter-key"

# Your IP address for SSH access (CIDR format). Example: "203.0.113.0/32"
your_ip_address = "203.0.113.0/32"

# Optional: Domain name
domain_name = ""

# Optional: Create Route53 DNS records
create_dns = false

# Monitoring and alarms
enable_monitoring = true
alarm_email       = ""
