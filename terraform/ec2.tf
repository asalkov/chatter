# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "chatter" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.chatter.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.chatter.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    delete_on_termination = false
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  user_data                   = templatefile("${path.module}/user-data.sh", {})
  user_data_replace_on_change = false
  
  monitoring = var.enable_monitoring
  
  tags = {
    Name = "${var.project_name}-server"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

# Elastic IP
resource "aws_eip" "chatter" {
  instance = aws_instance.chatter.id
  domain   = "vpc"
  
  tags = {
    Name = "${var.project_name}-eip"
  }
  
  depends_on = [aws_internet_gateway.main]
}
