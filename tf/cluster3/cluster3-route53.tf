# Route53 for instances

# cluster3 entries
resource "aws_route53_record" "cluster3" {
  zone_id = "${var.route53_zone_id}"
  count = "${var.cluster3_node_count}"
  name = "${var.prefix}-cluster3-${count.index + 1}.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_instance.cluster3.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "rke-cluster3" {
  zone_id = "${var.route53_zone_id}"
  name = "rke-cluster3.${var.route53_subdomain}.${var.route53_domain}"
  type = "CNAME"
  ttl = "60"
  records = [aws_route53_record.cluster3.0.name]
}

# cluster3 app elb
resource "aws_route53_record" "sec" {
  zone_id = "${var.route53_zone_id}"
  name = "cluster3.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  alias {
    name = "${aws_elb.cluster3-elb.dns_name}"
    zone_id = "${aws_elb.cluster3-elb.zone_id}"
    evaluate_target_health = false
  }
}

