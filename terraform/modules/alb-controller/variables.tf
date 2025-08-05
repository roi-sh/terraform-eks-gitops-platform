# for the cluster
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "roi-eks-cluster"
}

variable "region" {
    default = "eu-north-1"
}

variable "vpc" {
  description = "vpc from the vpc module (my_vpc)"
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL"
  type        = string
}