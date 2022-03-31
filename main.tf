module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.23.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version
  subnets         = data.aws_subnets.private.ids

  vpc_id = var.vpc_id

  # node_groups = {
  #   first = {
  #     desired_capacity = 1
  #     max_capacity     = 10
  #     min_capacity     = 1

  #     instance_type = "t2.small"
  #   }
  # }
  
  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
    },
  ]

  write_kubeconfig   = true
  kubeconfig_output_path = "./"


  workers_additional_policies = [aws_iam_policy.worker_policy.arn]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_iam_policy" "worker_policy" {
  name        = "worker-policy"
  description = "Worker policy for the ALB Ingress"

  policy = file("iam-policy.json")
}

# The Kubernetes service account for the AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_lb_controller" {
  metadata {
    name = "aws-load-balancer-controller"
  }

  secret {
    name = "${kubernetes_secret.aws_lb_controller.metadata.0.name}"
  }
}

resource "kubernetes_secret" "aws_lb_controller" {
  metadata {
    name = "aws-load-balancer-controller"
  }
}

# The AWS Load Balancer Controller can be deployed to the Kubernetes cluster using
# Helm.
resource "helm_release" "ingress" {
  name       = "ingress"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace = "kube-system"

  set {
    name = "region"
    value = "${var.aws_default_region}"
  }
  set {
    name = "vpcId"
    value = "${var.vpc_id}"
  }
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name = "image.repository"
    value = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }
  set {
    name = "serviceAccount.create"
    value = "false"
  }
  set {
    name = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}