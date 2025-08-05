# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get the latest EBS CSI driver version
data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.cluster_version
  most_recent        = var.use_most_recent_version
}

# IAM role for EBS CSI driver
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver-role"
      Purpose = "EBS CSI Driver for EKS"
    }
  )
}

# Attach AWS managed policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "aws_iam_policy" "ebs_csi_driver_custom" {
  count = var.create_custom_policy ? 1 : 0
  name  = "${var.cluster_name}-ebs-csi-driver-custom-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = [
              "CreateVolume",
              "CreateSnapshot"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver-custom-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_custom" {
  count      = var.create_custom_policy ? 1 : 0
  policy_arn = aws_iam_policy.ebs_csi_driver_custom[0].arn
  role       = aws_iam_role.ebs_csi_driver.name
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_version != "" ? var.addon_version : data.aws_eks_addon_version.ebs_csi_driver.version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  # Use the new attributes instead of deprecated resolve_conflicts
  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  resolve_conflicts_on_update = var.resolve_conflicts_on_update

  configuration_values = var.configuration_values

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}

# Default storage classes
resource "kubernetes_storage_class" "gp2" {
  count = var.create_gp2_storage_class ? 1 : 0

  metadata {
    name = "gp2"
    annotations = var.set_gp2_as_default ? {
      "storageclass.kubernetes.io/is-default-class" = "true"
    } : {}
    labels = var.storage_class_labels
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = var.volume_binding_mode
  allow_volume_expansion = var.allow_volume_expansion
  reclaim_policy        = var.reclaim_policy

  parameters = merge(
    {
      type   = "gp2"
      fsType = var.filesystem_type
    },
    var.gp2_parameters
  )

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

resource "kubernetes_storage_class" "gp3" {
  count = var.create_gp3_storage_class ? 1 : 0

  metadata {
    name = "gp3"
    annotations = var.set_gp3_as_default ? {
      "storageclass.kubernetes.io/is-default-class" = "true"
    } : {}
    labels = var.storage_class_labels
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = var.volume_binding_mode
  allow_volume_expansion = var.allow_volume_expansion
  reclaim_policy        = var.reclaim_policy

  parameters = merge(
    {
      type = "gp3"
      fsType = var.filesystem_type
    },
    var.gp3_parameters
  )

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# Custom storage classes
resource "kubernetes_storage_class" "custom" {
  for_each = var.custom_storage_classes

  metadata {
    name = each.key
    annotations = each.value.set_as_default ? {
      "storageclass.kubernetes.io/is-default-class" = "true"
    } : {}
    labels = merge(var.storage_class_labels, each.value.labels)
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = each.value.volume_binding_mode
  allow_volume_expansion = each.value.allow_volume_expansion
  reclaim_policy        = each.value.reclaim_policy

  parameters = each.value.parameters

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# Volume Snapshot Class (optional)
resource "kubernetes_manifest" "volume_snapshot_class" {
  count = var.create_volume_snapshot_class ? 1 : 0

  manifest = {
    apiVersion = "snapshot.storage.k8s.io/v1"
    kind       = "VolumeSnapshotClass"
    metadata = {
      name = var.volume_snapshot_class_name
      annotations = var.set_volume_snapshot_class_as_default ? {
        "snapshot.storage.kubernetes.io/is-default-class" = "true"
      } : {}
    }
    driver = "ebs.csi.aws.com"
    deletionPolicy = var.volume_snapshot_deletion_policy
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}