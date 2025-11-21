variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "chatter"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 20
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "your_ip_address" {
  description = "Your IP address for SSH access (CIDR format)"
  type        = string
  # Example: "203.0.113.0/32"

  validation {
    condition     = can(cidrhost(var.your_ip_address, 0))
    error_message = "Must be a valid CIDR block (e.g., 203.0.113.0/32)"
  }
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Must be a valid domain name (e.g., example.com)"
  }
}

variable "create_dns" {
  description = "Whether to create Route53 DNS records"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable CloudWatch detailed monitoring"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email for CloudWatch alarms"
  type        = string
  default     = ""

  validation {
    condition     = var.alarm_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alarm_email))
    error_message = "Must be a valid email address"
  }
}

variable "repository_url" {
  description = "Git repository URL for Chatter application (leave empty to deploy sample app)"
  type        = string
  default     = ""
}
