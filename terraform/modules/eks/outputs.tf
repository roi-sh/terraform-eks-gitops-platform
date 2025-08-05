output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.eks_cluster.id
}

output "cluster" {
  description = "EKS cluster "
  value       = aws_eks_cluster.eks_cluster
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.eks_worker_nodes_sg.id
}

output "node_group_role_arn" {
  description = "ARN of the worker nodes IAM role"
  value       = aws_iam_role.eks_node_group.arn
}

output "node_group_role_name" {
  description = "IAM role name for node group"
  value       = aws_iam_role.eks_node_group.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}