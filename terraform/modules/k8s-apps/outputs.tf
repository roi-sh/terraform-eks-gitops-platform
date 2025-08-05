# ArgoCD Password Command
output "argocd_password_command" {
  description = "Command to manually retrieve ArgoCD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

# ArgoCD Login Instructions
output "argocd_login_instructions" {
  description = "Instructions to login to ArgoCD"
  value = <<-EOT
    ArgoCD Login Instructions:
    1. URL: https://${local.argocd_fqdn}
    2. Username: admin
    3. Get password: kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    4. Weather App: https://${local.weather_fqdn}
  EOT
}

output "argocd_url" {
  description = "ArgoCD application URL"
  value       = "https://${local.argocd_fqdn}"
}

output "weather_app_url" {
  description = "Weather application URL"
  value       = "https://${local.weather_fqdn}"
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_roihub_ingress.id
}

output "route53_zone_id" {
  description = "Route53 zone ID"
  value       = data.aws_route53_zone.domain.zone_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = data.aws_lb.argocd_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = data.aws_lb.argocd_alb.zone_id
}

output "weather_app_iam_role_arn" {
  description = "ARN of the weather app IAM role"
  value       = aws_iam_role.weather_app_service_account_role.arn
}

output "weather_app_iam_role_name" {
  description = "Name of the weather app IAM role"
  value       = aws_iam_role.weather_app_service_account_role.name
}

output "weather_app_iam_policy_arn" {
  description = "ARN of the weather app IAM policy"
  value       = aws_iam_policy.weather_app_secrets_policy.arn
}

output "weather_app_service_account_name" {
  description = "Name of the weather app service account"
  value       = kubernetes_service_account.weather_app_sa.metadata[0].name
}

output "weather_app_service_account_namespace" {
  description = "Namespace of the weather app service account"
  value       = kubernetes_service_account.weather_app_sa.metadata[0].namespace
}

output "argocd_helm_release_name" {
  description = "Name of the ArgoCD Helm release"
  value       = helm_release.argo_cd.name
}

output "argocd_helm_release_namespace" {
  description = "Namespace of the ArgoCD Helm release"
  value       = helm_release.argo_cd.namespace
}

output "argocd_helm_release_version" {
  description = "Version of the ArgoCD Helm release"
  value       = helm_release.argo_cd.version
}

output "route53_records" {
  description = "Map of created Route53 records"
  value = {
    for subdomain in local.subdomains : subdomain => {
      name    = "${subdomain}.${var.domain_name}"
      type    = "A"
      zone_id = data.aws_route53_zone.domain.zone_id
    }
  }
}