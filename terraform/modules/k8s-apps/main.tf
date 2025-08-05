locals {
  argocd_fqdn = "${var.argocd_subdomain}.${var.domain_name}"
  weather_fqdn = "${var.weather_app_subdomain}.${var.domain_name}"
  subdomains = [var.argocd_subdomain, var.weather_app_subdomain]
  
  common_tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      ManagedBy = "terraform"
      Module    = "k8s-apps"
    }
  )
}

resource "aws_security_group" "alb_roihub_ingress" {
  name        = var.security_group_name
  description = "Allow inbound traffic on HTTP and HTTPS for ALB"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = var.security_group_name
    }
  )
}

data "aws_route53_zone" "domain" {
  name         = var.domain_name
  private_zone = var.route53_zone_private
}

# Get the ALB created by the ingress (must be created after Argo CD is deployed)
data "aws_lb" "argocd_alb" {
  depends_on = [helm_release.argo_cd]

  name = var.alb_name
  timeouts {
    read = var.alb_data_timeout
  }
}

resource "aws_route53_record" "app_aliases" {
  for_each = toset(local.subdomains)

  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.argocd_alb.dns_name
    zone_id                = data.aws_lb.argocd_alb.zone_id
    evaluate_target_health = true
  }

}

resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version != "" ? var.argocd_chart_version : null
  namespace        = var.argocd_namespace
  create_namespace = true
  timeout          = var.argocd_timeout

  values = [
    yamlencode({
      global = {
        domain = local.argocd_fqdn
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = true
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
            "alb.ingress.kubernetes.io/group.name" = var.ingress_group_name
            "alb.ingress.kubernetes.io/load-balancer-name" = var.alb_name
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\":443}, {\"HTTP\":80}]"
            "alb.ingress.kubernetes.io/ssl-redirect" = "443"
            "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
            "alb.ingress.kubernetes.io/security-groups" = aws_security_group.alb_roihub_ingress.id
            "alb.ingress.kubernetes.io/manage-backend-security-group-rules" = "false"
            "alb.ingress.kubernetes.io/conditions.argocd" = jsonencode([{
              field = "host-header"
              hostHeaderConfig = {
                values = [local.argocd_fqdn]
              }
            }])
          }
          hosts = [{
            host = local.argocd_fqdn
            paths = [{
              path = "/"
              pathType = "Prefix"
            }]
          }]
          tls = [{
            hosts = [local.argocd_fqdn]
          }]
        }
        extraArgs = ["--insecure"]
      }
      dex = {
        enabled = false
      }
      configs = {
        params = {
          "server.insecure" = true
        }
      }
    })
  ]
}

resource "kubectl_manifest" "argo_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.weather_app_name}
  namespace: ${var.argocd_namespace}
spec:
  project: default
  source:
    repoURL: ${var.weather_app_git_repo}
    targetRevision: ${var.weather_app_git_branch}
    path: ${var.weather_app_helm_path}
    helm:
      values: |
        # Weather App Configuration
        weatherapp:
          name: ${var.weather_app_name}
          namespace: ${var.namespace}
          replicaCount: ${var.weather_app_replica_count}
          image:
            repository: ${var.weather_app_image_repository}
            tag: ${var.weather_app_image_tag}
          service:
            type: ${var.weather_app_service_type}
            port: ${var.weather_app_service_port}
            targetPort: ${var.weather_app_target_port}

        # ConfigMap Configuration
        configmap:
          ${var.weather_app_name}:
            name: ${var.weather_app_name}-configmap
            data:
              BG_COLOR: "${var.weather_app_bg_color}"
              SECRET_NAME: "${var.weather_app_secret_name}"
              AWS_REGION: "${var.region}"

        # Ingress Configuration
        ingress:
          enabled: ${var.weather_app_ingress_enabled}
          ${var.weather_app_name}:
            host: ${local.weather_fqdn}
            annotations:
              alb.ingress.kubernetes.io/scheme: internet-facing
              alb.ingress.kubernetes.io/target-type: ip
              alb.ingress.kubernetes.io/group.name: ${var.ingress_group_name}
              alb.ingress.kubernetes.io/load-balancer-name: ${var.alb_name}
              alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
              alb.ingress.kubernetes.io/ssl-redirect: '443'
              alb.ingress.kubernetes.io/manage-backend-security-group-rules: "false"
              alb.ingress.kubernetes.io/certificate-arn: "${var.certificate_arn}"
              alb.ingress.kubernetes.io/conditions.${var.weather_app_name}: |
                [{
                  "field": "host-header",
                  "hostHeaderConfig": {
                    "values": ["${local.weather_fqdn}"]
                  }
                }]
            spec:
              ingressClassName: alb
              rules:
                http:
                  paths:
                    path: /
                    pathType: Prefix

        # EFS Configuration
        efs:
          enabled: true
          name: ${var.efs_storage_class_name}
          provisioner: efs.csi.aws.com
          parameters:
            provisioningMode: ${var.efs_provisioning_mode}
            fileSystemId: "${var.efs}"
            directoryPerms: "${var.efs_directory_perms}"
            region: "${var.region}"

        # PVC Configuration
        pvc:
          enabled: ${var.pvc_enabled}
          name: ${var.pvc_name}
          storageClass: "${var.efs_storage_class_name}"
          size: "${var.pvc_size}"
          accessMode: "${var.pvc_access_mode}"
          mountPath: "${var.pvc_mount_path}"

  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.namespace}
  syncPolicy:
    automated:
      prune: ${var.argocd_auto_prune}
      selfHeal: ${var.argocd_self_heal}
    syncOptions:
    - CreateNamespace=true
    - Replace=true
YAML

  depends_on = [
    helm_release.argo_cd
  ]
}

resource "null_resource" "print_argocd_password" {
  triggers = {
    argo_cd_release = helm_release.argo_cd.id
    argo_app        = kubectl_manifest.argo_app.id
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "=== PHASE 1 DEPLOYMENT COMPLETE ==="
      echo "ArgoCD and applications have been deployed!"
      echo ""
      echo "Getting ArgoCD admin password..."

      # Wait a bit for the secret to be created
      sleep ${var.secret_wait_time}

      PASSWORD=$(kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

      if [ "$PASSWORD" != "" ]; then
        echo "ArgoCD Admin Password: $PASSWORD"
      else
        echo "ArgoCD admin password not ready yet. Use this command later:"
        echo "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
      fi

      echo ""
      echo "=== NEXT STEPS FOR PHASE 2 ==="
      echo "1. Wait 5-10 minutes for ALB to be created by AWS Load Balancer Controller"
      echo "2. Check ALB status: kubectl get ingress -n ${var.argocd_namespace}"
      echo "3. Verify ALB exists: aws elbv2 describe-load-balancers --region ${var.region} --query 'LoadBalancers[?LoadBalancerName==\`${var.alb_name}\`]'"
      echo "4. Uncomment Route53 records in main.tf and run 'terraform apply' again"
      echo ""
      echo "Expected URLs after Phase 2:"
      echo "ArgoCD: https://${local.argocd_fqdn}"
      echo "Weather App: https://${local.weather_fqdn}"
    EOT
  }

  depends_on = [
    kubectl_manifest.argo_app
  ]
}