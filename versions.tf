terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.3.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }

    backend "http" {}
}