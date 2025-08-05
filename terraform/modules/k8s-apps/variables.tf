variable "region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL for the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for applications"
  type        = string
}

variable "weather_api_key" {
  description = "Weather API key secret name in AWS Secrets Manager"
  type        = string
  sensitive   = true
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account for weather app"
  type        = string
}

variable "vpc" {
  description = "VPC object from the VPC module"
  type        = object({
    id = string
  })
}

variable "efs" {
  description = "EFS filesystem ID"
  type        = string
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

variable "argocd_timeout" {
  description = "Timeout for ArgoCD Helm installation in seconds"
  type        = number
  default     = 600
}

# Domain Configuration
variable "domain_name" {
  description = "Base domain name for applications"
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

variable "certificate_arn" {
  description = "ARN of the SSL certificate in ACM"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "alb-for-cluster"
}

variable "ingress_group_name" {
  description = "Name of the ALB ingress group"
  type        = string
  default     = "ingress-group"
}

variable "security_group_name" {
  description = "Name of the security group for ALB"
  type        = string
  default     = "alb-ingress"
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

variable "weather_app_git_branch" {
  description = "Git branch for weather app"
  type        = string
  default     = "main"
}

variable "weather_app_helm_path" {
  description = "Path to Helm chart in Git repository"
  type        = string
  default     = "weatherapp"
}

variable "weather_app_bg_color" {
  description = "Background color for weather app"
  type        = string
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

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.weather_app_service_type)
    error_message = "Service type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
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

variable "efs_provisioning_mode" {
  description = "EFS provisioning mode"
  type        = string
  default     = "efs-ap"
}

variable "efs_directory_perms" {
  description = "Directory permissions for EFS"
  type        = string
  default     = "0755"
}

variable "efs_storage_class_name" {
  description = "Name of the EFS storage class"
  type        = string
  default     = "efs-sc"
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

  validation {
    condition = contains([
      "ReadWriteOnce",
      "ReadOnlyMany",
      "ReadWriteMany",
      "ReadWriteOncePod"
    ], var.pvc_access_mode)
    error_message = "PVC access mode must be one of: ReadWriteOnce, ReadOnlyMany, ReadWriteMany, ReadWriteOncePod."
  }
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

variable "route53_zone_private" {
  description = "Whether the Route53 zone is private"
  type        = bool
  default     = false
}

variable "argocd_auto_prune" {
  description = "Enable auto pruning for ArgoCD applications"
  type        = bool
  default     = true
}

variable "argocd_self_heal" {
  description = "Enable self healing for ArgoCD applications"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for AWS resources"
  type        = map(string)
  default     = {}
}

variable "alb_data_timeout" {
  description = "Timeout for ALB data source in minutes"
  type        = string
  default     = "10m"
}

variable "secret_wait_time" {
  description = "Wait time in seconds for secrets to be created"
  type        = number
  default     = 10
}