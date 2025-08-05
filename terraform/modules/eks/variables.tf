variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

# for the cluster
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "roi-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
  default     = "t3.xlarge"
}

variable "desired_node_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "private_subnets" {
  description = "private subnets from vpc"
}

variable "public_subnets" {
  description = "public_subnet from vpc"
}

variable "vpc" {
  description = "vpc id from the vpc module (my_vpc)"
}