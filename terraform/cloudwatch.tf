# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  count = var.alarm_email != "" ? 1 : 0
  name  = "${var.project_name}-alarms"
  
  tags = {
    Name = "${var.project_name}-alarms"
  }
}

# SNS Subscription
resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Alarm - CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  
  dimensions = {
    InstanceId = aws_instance.chatter.id
  }
}

# CloudWatch Alarm - Status Check Failed
resource "aws_cloudwatch_metric_alarm" "status_check" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 status checks"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  
  dimensions = {
    InstanceId = aws_instance.chatter.id
  }
}

# CloudWatch Alarm - Disk Space
# Note: This alarm uses EBS volume metrics instead of CloudWatch agent
# For more detailed disk metrics, install CloudWatch agent on the instance
resource "aws_cloudwatch_metric_alarm" "disk_space" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-disk-space-low"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeReadOps"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This metric monitors EBS volume operations as a proxy for disk activity"
  alarm_actions       = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    VolumeId = aws_instance.chatter.root_block_device[0].volume_id
  }
}
