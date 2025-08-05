# Output EFS ID for Kubernetes PV configuration
output "efs_id" {
  value = aws_efs_file_system.eks_efs.id
}

output "efs_access_point_id" {
  value = aws_efs_access_point.eks_access_point.id
}