locals {
  weather_app_policy_name = "WeatherAppSecretsPolicy-${var.cluster_name}"
  weather_app_role_name   = "weather-app-service-account-role-${var.cluster_name}"
  secrets_resource_arn    = "arn:aws:secretsmanager:${var.region}:${var.aws_account_id}:secret:${var.weather_api_key}*"
  
  oidc_provider_clean_url = replace(var.oidc_provider_url, "https://", "")
  service_account_subject = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

# Create IAM policy for accessing Secrets Manager
resource "aws_iam_policy" "weather_app_secrets_policy" {
  name        = local.weather_app_policy_name
  description = "Policy to allow weather app to access secrets from Secrets Manager for cluster ${var.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.secrets_resource_arn
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Application = var.weather_app_name
      Purpose     = "secrets-access"
    }
  )
}

# Create IAM role for service account (IRSA)
resource "aws_iam_role" "weather_app_service_account_role" {
  name = local.weather_app_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_clean_url}:sub" = local.service_account_subject
            "${local.oidc_provider_clean_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Application = var.weather_app_name
      Purpose     = "service-account-role"
    }
  )
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "weather_app_secrets_policy_attachment" {
  role       = aws_iam_role.weather_app_service_account_role.name
  policy_arn = aws_iam_policy.weather_app_secrets_policy.arn
}

# Kubernetes service account
resource "kubernetes_service_account" "weather_app_sa" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.weather_app_service_account_role.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
    labels = merge(
      {
        app                                = var.weather_app_name
        "app.kubernetes.io/name"           = var.weather_app_name
        "app.kubernetes.io/component"      = "service-account"
        "app.kubernetes.io/managed-by"     = "terraform"
      }
    )
  }

  automount_service_account_token = true

  depends_on = [
    aws_iam_role.weather_app_service_account_role
  ]
}