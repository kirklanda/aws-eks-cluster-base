resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "amazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}


data "aws_arn" "oidc_provider_arn" {
  arn = aws_iam_openid_connect_provider.cluster.arn
}

# Read the IAM Policy that will be attached to the load balancer controller role
data "template_file" "oidc_trust_relationship_policy" {
  template = "${file("oidc_trust_relationship_policy.tpl")}"

  vars = {
    oidc_provider_arn = aws_iam_openid_connect_provider.cluster.arn
    oidc_provider_id = data.aws_arn.oidc_provider_arn.resource
  }

  # The template for the policy can only be created after the OIDC provider exists
  depends_on = [aws_iam_openid_connect_provider.cluster]
}

data "aws_iam_policy_document" "federated_identity_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    condition {
      test = "StringEquals"
      variable = format("%s:sub", aws_iam_openid_connect_provider.cluster.url)
      values = [
        format("system:serviceaccount:%s:%s", var.kube_namespace, var.lb_service_account)
      ]
    }
  }
}

# A role for the AWS Load Balancer Controller.
resource "aws_iam_role" "amazonEKSLoadBalancerControllerRole" {
  name = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.federated_identity_policy.json
}

# Give the AmazonEKSLoadBalancerControllerRole the AWSLoadBalancerControllerPolicy also
resource "aws_iam_role_policy_attachment" "alb_controller_policy_attachment" {
  role = aws_iam_role.amazonEKSLoadBalancerControllerRole.name
  policy_arn = aws_iam_policy.alb_load_balancer_controller.arn
}

# Attach the additional policy to the AmazonEKSLoadBalancerControllerRole
resource "aws_iam_role_policy_attachment" "alb_controller_additional_policy_attachment" {
  role = aws_iam_role.amazonEKSLoadBalancerControllerRole.name
  policy_arn = aws_iam_policy.alb_load_balancer_controller_v1_to_v2_additional.arn
}

# The Kubernetes service account that corresponds to the ALB Controller Role
resource "kubernetes_service_account" "alb_controller_service_account" {
  metadata {
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name" = "${var.lb_service_account}"
    }
    name = "${var.lb_service_account}"
    namespace = "${var.kube_namespace}"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.amazonEKSLoadBalancerControllerRole.arn}"
    }
  }
}