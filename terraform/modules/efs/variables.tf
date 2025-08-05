variable "cidr_block" {
    default = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster" {
  description = "the eks cluster"
}

variable "vpc" {
  description = "vpc from the vpc module (my_vpc)"
}

variable "private_subnets" {
  description = "private subnet for the efs"
}

variable "eks_worker_nodes_sg" {
  description = "worker node security group (need the id) to add efs port"
}

variable "eks_node_group" {
  description = "need the name of the Node Group IAM Role to attach new efs role"
}

variable "efs_csi_driver_version" {
  description = "Version of the EFS CSI driver addon"
  type        = string
  default     = "v2.1.8-eksbuild.1"
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from EKS module"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from EKS module"
  type        = string
}