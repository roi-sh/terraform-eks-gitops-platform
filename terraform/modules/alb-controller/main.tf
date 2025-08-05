data "local_file" "alb_iam_policy" {
  filename = "${path.module}/iam-policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  description = "Policy for AWS Load Balancer Controller for ${var.cluster_name}"
  policy      = data.local_file.alb_iam_policy.content
}

# Create IAM Role and Service Account
data "aws_iam_policy_document" "alb_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    # Only tokens issued by this OIDC provider are allowed to assume this role
    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "AmazonEKSLoadBalancerControllerRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

# Create Kubernetes Service Account
resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "aws_security_group" "alb_controller_sg" {
  name_prefix = "alb-controller-"
  description = "Security group for ALB Controller"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-controller-sg"
  }
}

# Install ALB Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  timeout = 600

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc.id
  }

  set {
    name  = "ingressClass"
    value = "alb"
  }
  set {
    name  = "securityGroup.create"
    value = "false"
  }

  set {
    name  = "securityGroup.id"
    value = aws_security_group.alb_controller_sg.id
  }

  depends_on = [
    kubernetes_service_account.alb_controller,
    aws_security_group.alb_controller_sg
  ]
}

#Null resource to delete the ALB named "alb-for-cluster"
resource "null_resource" "delete_alb_for_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    region       = var.region  # Store region in triggers so it's available during destroy
    timestamp    = timestamp()
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Get the ALB ARN by name
      ALB_ARN=$(aws elbv2 describe-load-balancers \
        --region ${self.triggers.region} \
        --names "alb-for-cluster" \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text 2>/dev/null || echo "None")

      if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "null" ]; then
        echo "Found ALB with ARN: $ALB_ARN"
        echo "Deleting ALB: alb-for-cluster"
        aws elbv2 delete-load-balancer \
          --region ${self.triggers.region} \
          --load-balancer-arn "$ALB_ARN"
        echo "ALB deletion initiated successfully"
      else
        echo "ALB 'alb-for-cluster' not found or already deleted"
      fi
    EOT
  }
}