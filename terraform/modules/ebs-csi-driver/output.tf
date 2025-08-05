# modules/ebs-csi-driver/outputs.tf

# IAM Role Outputs
output "iam_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "iam_role_name" {
  description = "Name of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.name
}

output "iam_role_unique_id" {
  description = "Unique ID of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver.unique_id
}

# EKS Addon Outputs
output "addon_arn" {
  description = "ARN of the EBS CSI driver addon"
  value       = aws_eks_addon.ebs_csi_driver.arn
}


output "addon_version" {
  description = "Version of the EBS CSI driver addon"
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}

output "addon_created_at" {
  description = "Date and time the addon was created"
  value       = aws_eks_addon.ebs_csi_driver.created_at
}

# Storage Class Outputs
output "gp2_storage_class_name" {
  description = "Name of the gp2 storage class"
  value       = var.create_gp2_storage_class ? kubernetes_storage_class.gp2[0].metadata[0].name : null
}

output "gp3_storage_class_name" {
  description = "Name of the gp3 storage class"
  value       = var.create_gp3_storage_class ? kubernetes_storage_class.gp3[0].metadata[0].name : null
}

output "custom_storage_class_names" {
  description = "Names of custom storage classes"
  value       = [for k, v in kubernetes_storage_class.custom : v.metadata[0].name]
}

output "default_storage_class" {
  description = "Name of the default storage class"
  value = var.set_gp2_as_default && var.create_gp2_storage_class ? "gp2" : (
    var.set_gp3_as_default && var.create_gp3_storage_class ? "gp3" : (
      length([for k, v in var.custom_storage_classes : k if v.set_as_default]) > 0 ?
      [for k, v in var.custom_storage_classes : k if v.set_as_default][0] :
      "none"
    )
  )
}

# Volume Snapshot Class Outputs
output "volume_snapshot_class_name" {
  description = "Name of the volume snapshot class"
  value       = var.create_volume_snapshot_class ? var.volume_snapshot_class_name : null
}

# Service Account Information
output "ebs_csi_controller_service_account" {
  description = "Service account used by EBS CSI controller"
  value       = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
}

# Policy ARNs
output "managed_policy_arn" {
  description = "ARN of the AWS managed policy attached to the role"
  value       = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

output "custom_policy_arn" {
  description = "ARN of the custom policy (if created)"
  value       = var.create_custom_policy ? aws_iam_policy.ebs_csi_driver_custom[0].arn : null
}

# Verification Commands
output "verification_commands" {
  description = "Commands to verify the EBS CSI driver installation"
  value = {
    check_addon_status    = "aws eks describe-addon --cluster-name ${var.cluster_name} --addon-name aws-ebs-csi-driver"
    check_pods           = "kubectl get pods -n kube-system -l app=ebs-csi-controller"
    check_storage_classes = "kubectl get storageclass"
    check_csi_driver     = "kubectl get csidriver ebs.csi.aws.com"
    test_volume_creation = "kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/examples/kubernetes/dynamic-provisioning/manifests/claim.yaml"
  }
}

# Configuration Summary
output "configuration_summary" {
  description = "Summary of EBS CSI driver configuration"
  value = {
    cluster_name          = var.cluster_name
    addon_version        = aws_eks_addon.ebs_csi_driver.addon_version
    iam_role_arn         = aws_iam_role.ebs_csi_driver.arn
    gp2_storage_class    = var.create_gp2_storage_class
    gp3_storage_class    = var.create_gp3_storage_class
    default_storage_class = var.set_gp2_as_default && var.create_gp2_storage_class ? "gp2" : (
      var.set_gp3_as_default && var.create_gp3_storage_class ? "gp3" : "custom"
    )
    volume_binding_mode   = var.volume_binding_mode
    allow_volume_expansion = var.allow_volume_expansion
    reclaim_policy       = var.reclaim_policy
    filesystem_type      = var.filesystem_type
  }
}