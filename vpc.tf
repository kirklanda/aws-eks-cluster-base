data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }

  # Retrieve only the public subnets with a tag of "Tier" set to "Public"
  tags = {
    Tier = "Public"
  }
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }

  # Retrieve only the private subnets with a tag of "Tier" set to "Private"
  tags = {
    Tier = "Private"
  }
}

# Add the additional tags needed by EKS
resource "aws_ec2_tag" "private_subnet_cluster_tag" {
  for_each = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key = "kubernetes.io/cluster/${var.cluster_name}"
  value = "owned"
}

resource "aws_ec2_tag" "public_subnet_cluster_tag" {
  for_each = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key = "kubernetes.io/cluster/${var.cluster_name}"
  value = "owned"
}

# Application load balancing looks for the following tag
resource "aws_ec2_tag" "private_elb_tag" {
  for_each = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key = "kubernetes.io/role/internal-elb"
  value = "1"
}

resource "aws_ec2_tag" "public_elb_tag" {
  for_each = toset(data.aws_subnets.public.ids)
  resource_id = each.value
  key = "kubernetes.io/role/elb"
  value = 1
}