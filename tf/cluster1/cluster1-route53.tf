# Route53 for instances

# cluster1 entries
resource "aws_route53_record" "cluster1" {
  zone_id = "${var.route53_zone_id}"
  count = "${var.cluster1_node_count}"
  name = "${var.prefix}-cluster1-${count.index + 1}.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.cluster1.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "rke-cluster1" {
  zone_id = "${var.route53_zone_id}"
  name = "rke-cluster1.${var.route53_subdomain}.${var.route53_domain}"
  type = "CNAME"
  ttl = "60"
  records = [aws_route53_record.cluster1.0.name]
}

