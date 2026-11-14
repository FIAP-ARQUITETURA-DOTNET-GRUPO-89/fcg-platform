resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "observability"
  create_namespace = true
  wait             = true
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 900

  values = [
    file("${path.module}/../../../k8s/infrastructure/observability/values-kube-prometheus-stack.yaml")
  ]

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}
