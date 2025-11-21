# IAM Role for Data Lifecycle Manager
resource "aws_iam_role" "dlm_lifecycle" {
  name = "${var.project_name}-dlm-lifecycle-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-dlm-lifecycle-role"
  }
}

resource "aws_iam_role_policy_attachment" "dlm_lifecycle" {
  role       = aws_iam_role.dlm_lifecycle.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

# DLM Lifecycle Policy for EBS Snapshots (daily, retain 7)
resource "aws_dlm_lifecycle_policy" "chatter_backups" {
  description        = "Daily EBS snapshots for ${var.project_name}"
  execution_role_arn = aws_iam_role.dlm_lifecycle.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        Project         = var.project_name
      }

      copy_tags = true
    }

    # Target volumes tagged by Name in root_block_device
    target_tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-dlm-policy"
  }
}
