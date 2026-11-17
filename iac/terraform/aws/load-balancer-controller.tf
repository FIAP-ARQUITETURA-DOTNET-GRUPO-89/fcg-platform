
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.14.0"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName  = var.cluster_name
      region       = var.aws_region
      vpcId        = data.aws_vpc.default.id
      replicaCount = 1

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"

        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.load_balancer_controller.arn
        }
      }
    })
  ]

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.load_balancer_controller,
    aws_ec2_tag.public_load_balancer
  ]
}
