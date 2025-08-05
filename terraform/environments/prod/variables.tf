variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "private_subnet" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnet" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "node_instance_type" {
  description = "Instance type for EKS worker nodes"
  type        = string
}

variable "desired_node_count" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "max_node_count" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "min_node_count" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "efs_csi_driver_version" {
  description = "Version of the EFS CSI driver"
  type        = string
}

variable "alb_name" {
  description = "Name for the Application Load Balancer"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "weather_api_key" {
  description = "Weather API key (stored in AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
}

variable "domain_name" {
  description = "Base domain name for applications"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate in ACM"
  type        = string
}

variable "argocd_subdomain" {
  description = "Subdomain for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "weather_app_subdomain" {
  description = "Subdomain for Weather App"
  type        = string
  default     = "weather"
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of ArgoCD Helm chart"
  type        = string
  default     = ""
}

variable "weather_app_name" {
  description = "Name of the weather application"
  type        = string
  default     = "weatherapp"
}

variable "weather_app_git_repo" {
  description = "Git repository URL for weather app Helm chart"
  type        = string
}

variable "weather_app_bg_color" {
  description = "Background color for weather app"
  type        = string
  default     = ""
}

variable "weather_app_replica_count" {
  description = "Number of replicas for weather app"
  type        = number
  default     = 2
}

variable "weather_app_image_repository" {
  description = "Docker image repository for weather app"
  type        = string
}

variable "weather_app_image_tag" {
  description = "Docker image tag for weather app"
  type        = string
  default     = "latest"
}

variable "weather_app_service_type" {
  description = "Kubernetes service type for weather app"
  type        = string
  default     = "ClusterIP"
}

variable "weather_app_service_port" {
  description = "Service port for weather app"
  type        = number
  default     = 5000
}

variable "weather_app_target_port" {
  description = "Target port for weather app"
  type        = number
  default     = 5000
}

variable "weather_app_secret_name" {
  description = "AWS Secrets Manager secret name for weather app"
  type        = string
}

variable "pvc_enabled" {
  description = "Enable PVC for weather app"
  type        = bool
  default     = true
}

variable "pvc_name" {
  description = "Name of the PVC"
  type        = string
  default     = "weatherapp-storage"
}

variable "pvc_size" {
  description = "Size of the PVC"
  type        = string
  default     = "1Gi"
}

variable "pvc_access_mode" {
  description = "Access mode for PVC"
  type        = string
  default     = "ReadWriteOnce"
}

variable "pvc_mount_path" {
  description = "Mount path for PVC in containers"
  type        = string
  default     = "/weather_history"
}

variable "weather_app_ingress_enabled" {
  description = "Enable ingress for weather app"
  type        = bool
  default     = true
}