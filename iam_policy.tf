# Create an IAM Policy for the AWS Load Balancer Controller
resource "aws_iam_policy" "alb_load_balancer_controller" {
  name = "AWSLoadBalancerControllerPolicy"
  description = "An IAM Policy for allowing the AWS Load Balancer Controller to make AWS API calls"
  policy = file("iam_policy_alb_controller.json")
}

# Another policy that needs to be added to the AWSLoadBalancerControllerRole
resource "aws_iam_policy" "alb_load_balancer_controller_v1_to_v2_additional" {
  name = "AWSLoadBalancerControllerAdditionalIAMPolicy"
  description = "An additional Policy that allows the AWS Load Balancer Controller access to resources created by the older ALB Ingress Controller"
  policy = file("iam_policy_v1_to_v2_additional.json")
} 