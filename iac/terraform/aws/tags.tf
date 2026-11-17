
# Tags para descoberta de subnets públicas pelo AWS Load Balancer Controller

resource "aws_ec2_tag" "public_load_balancer" {
  for_each = toset(data.aws_subnets.default.ids)

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
