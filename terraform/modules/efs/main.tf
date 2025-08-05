resource "aws_security_group" "efs_sg" {
  name        = "efs-sg-${var.cluster_name}"
  description = "Allow NFS traffic from EKS worker nodes"
  vpc_id      = var.vpc.id

  # Allow NFS traffic from VPC CIDR
  ingress {
    description      = "Allow NFS traffic from within VPC"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_block]
  }

  # Allow NFS traffic from worker nodes security group
  ingress {
    description     = "Allow NFS traffic from worker nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.eks_worker_nodes_sg]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-sg-${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "efs_from_cluster" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = var.eks_cluster.vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.efs_sg.id
  description              = "Allow NFS traffic from cluster"
}

# Create EFS file system
resource "aws_efs_file_system" "eks_efs" {
  creation_token = "efs-${var.cluster_name}"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "efs-${var.cluster_name}"
  }
}

# Create mount targets in each private subnet
resource "aws_efs_mount_target" "efs_mount_targets" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.eks_efs.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

# Create an EFS access point for Kubernetes
resource "aws_efs_access_point" "eks_access_point" {
  file_system_id = aws_efs_file_system.eks_efs.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/weather_history"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "eks-access-point-${var.cluster_name}"
  }
}

# IAM Role for EFS CSI Driver Service Account
resource "aws_iam_role" "efs_csi_driver" {
  name = "AmazonEKS_EFS_CSI_DriverRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub"  = "system:serviceaccount:kube-system:efs-csi-controller-sa",
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the AWS managed EFS CSI Driver policy
resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}

# EFS CSI Driver Addon
resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name                = var.eks_cluster.name
  addon_name                 = "aws-efs-csi-driver"
  addon_version              = "v2.1.8-eksbuild.1" # there is variable version
  service_account_role_arn   = aws_iam_role.efs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.efs_csi_driver_policy,
  ]

  tags = {
    Name = "efs-csi-driver-${var.cluster_name}"
  }
}

# Create StorageClass for EFS
resource "kubectl_manifest" "efs_storage_class" {
  yaml_body = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${aws_efs_file_system.eks_efs.id}
  directoryPerms: "0755"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/dynamic_provisioning"
reclaimPolicy: Delete
volumeBindingMode: Immediate
YAML

  depends_on = [
    aws_eks_addon.efs_csi_driver
  ]
}

resource "aws_iam_role_policy_attachment" "worker_node_efs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = var.eks_node_group
}
