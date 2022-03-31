variable "lab_environment_name" {
  description = "A unique name for the lab environment that will distinguish it from other labs"
  type = string
}

variable "aws_default_region" {
  description = "The AWS region to use for the lab"
  type = string
}

variable "aws_access_key_id" {
  type = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type = string
  sensitive = true
}

variable "vpc_id" {
  description = "The ID of the VPC that services will be provisioned into"
  type = string
}

variable "cluster_name" {
  description = "The descriptive name for the EKS cluster"
  type = string
}

variable "oidc_thumbprint_list" {
  type = list(string)
  default = []
}

variable "kubernetes_version" {
  type = string
  default = "1.21"
}

variable "kube_namespace" {
  type = string
  default = "kube-system"
}

variable "lb_service_account" {
  type = string
  default = "aws-load-balancer-controller"
}