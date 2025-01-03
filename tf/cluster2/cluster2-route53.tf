# Route53 for instances

# cluster2 entries
resource "aws_route53_record" "cluster2" {
  zone_id = "${var.route53_zone_id}"
  count = "${var.cluster2_node_count}"
  name = "${var.prefix}-cluster2-${count.index + 1}.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.cluster2.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "rke-cluster2" {
  zone_id = "${var.route53_zone_id}"
  name = "rke-cluster2.${var.route53_subdomain}.${var.route53_domain}"
  type = "CNAME"
  ttl = "60"
  records = [aws_route53_record.cluster2.0.name]
}

# security elb
resource "aws_route53_record" "sec" {
  zone_id = "${var.route53_zone_id}"
  name = "sec.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  alias {
    name = "${aws_elb.cluster2-elb.dns_name}"
    zone_id = "${aws_elb.cluster2-elb.zone_id}"
    evaluate_target_health = false
  }
}

