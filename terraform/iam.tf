# IAM Role for EC2 Instance
resource "aws_iam_role" "chatter_ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Attach CloudWatch Agent permissions
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.chatter_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM permissions (useful for remote management)
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.chatter_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "chatter" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.chatter_ec2.name
}
