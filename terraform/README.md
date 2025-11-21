# Chatter Terraform Deployment

Infrastructure as Code for deploying Chatter to AWS.

## Quick Start

1. **Install Terraform**
   ```bash
   # Download from https://www.terraform.io/downloads
   # Or use package manager
   ```

2. **Configure AWS CLI**
   ```bash
   aws configure
   ```

3. **Create SSH Key Pair**
   ```bash
   aws ec2 create-key-pair --key-name chatter-key --query 'KeyMaterial' --output text > ~/.ssh/chatter-key.pem
   chmod 400 ~/.ssh/chatter-key.pem
   ```

4. **Copy and Edit Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars
   ```
   
   **Required variables:**
   - `ssh_key_name` - Your AWS SSH key pair name
   - `your_ip_address` - Your IP in CIDR format (e.g., "1.2.3.4/32")
   
   **Optional variables:**
   - `repository_url` - Git repo URL for automatic deployment
   - `alarm_email` - Email for CloudWatch alerts
   - `domain_name` - Your domain for DNS setup

5. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

6. **Get Connection Info**
   ```bash
   terraform output
   ```

## What Gets Created

- ✅ VPC with 2 public subnets
- ✅ Internet Gateway
- ✅ Security Group (SSH, HTTP, HTTPS)
- ✅ EC2 t3.micro instance (Ubuntu 22.04)
- ✅ Elastic IP (static IP)
- ✅ 20GB gp3 EBS volume
- ✅ CloudWatch monitoring and alarms
- ✅ Optional: Route53 DNS records

## Cost

**~$10-15/month**

## Files

See [../terraform.md](../terraform.md) for complete documentation and all Terraform configuration files.

## After Deployment

1. SSH into instance
2. Clone repository
3. Deploy backend and frontend
4. Configure Nginx
5. Set up SSL with Let's Encrypt

See [../plan.md](../plan.md) for detailed deployment steps.

## Destroy

```bash
terraform destroy
```

**Warning**: This deletes everything!
