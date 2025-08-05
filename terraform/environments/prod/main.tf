data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}


module "vpc" {
  source = "../../modules/vpc"

  region = var.region
  cidr_block            = var.cidr_block
  azs                   = local.availability_zones
  private_subnet        = var.private_subnet
  public_subnet         = var.public_subnet
  alb_name              = var.alb_name
}


module "eks" {
  source = "../../modules/eks"
  region = var.region
  cluster_name = var.cluster_name
  cluster_version = var.cluster_version
  node_instance_type = var.node_instance_type
  desired_node_count = var.desired_node_count
  max_node_count = var.max_node_count
  min_node_count = var.min_node_count
  private_subnets = module.vpc.private_subnets
  public_subnets = module.vpc.public_subnets
  vpc = module.vpc.vpc

  depends_on = [module.vpc]

}


module "efs" {
  source = "../../modules/efs"

  cidr_block = var.cidr_block
  cluster_name = var.cluster_name
  eks_cluster = module.eks.cluster
  vpc = module.vpc.vpc
  private_subnets = module.vpc.private_subnets
  eks_worker_nodes_sg = module.eks.worker_security_group_id
  eks_node_group = module.eks.node_group_role_name
  efs_csi_driver_version = var.efs_csi_driver_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  depends_on = [module.eks]
}

module "alb-controller" {
  source = "../../modules/alb-controller"

  cluster_name = var.cluster_name
  region = var.region
  vpc = module.vpc.vpc
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  depends_on = [
    module.eks,
    module.efs
  ]
}

# Kubernetes Applications Module
module "k8s_apps" {
  source = "../../modules/k8s-apps"

  region = var.region
  aws_account_id = var.aws_account_id
  cluster_name = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  namespace = var.namespace
  weather_api_key = var.weather_api_key
  service_account_name = var.service_account_name
  vpc = module.vpc.vpc
  efs = module.efs.efs_id
  domain_name       = var.domain_name
  certificate_arn   = var.certificate_arn

  argocd_subdomain      = var.argocd_subdomain
  weather_app_subdomain = var.weather_app_subdomain

  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version

  alb_name             = var.alb_name

  weather_app_name       = var.weather_app_name
  weather_app_git_repo   = var.weather_app_git_repo
  weather_app_bg_color   = var.weather_app_bg_color

  weather_app_replica_count     = var.weather_app_replica_count
  weather_app_image_repository  = var.weather_app_image_repository
  weather_app_image_tag         = var.weather_app_image_tag
  weather_app_service_type      = var.weather_app_service_type
  weather_app_service_port      = var.weather_app_service_port
  weather_app_target_port       = var.weather_app_target_port
  weather_app_secret_name       = var.weather_app_secret_name
  weather_app_ingress_enabled   = var.weather_app_ingress_enabled

  pvc_enabled     = var.pvc_enabled
  pvc_name        = var.pvc_name
  pvc_size        = var.pvc_size
  pvc_access_mode = var.pvc_access_mode
  pvc_mount_path  = var.pvc_mount_path

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [module.eks, module.efs]
}