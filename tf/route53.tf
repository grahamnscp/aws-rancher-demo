# Route53 for instances

resource "aws_route53_record" "ran" {
  zone_id = "${var.route53_zone_id}"
  count = "${var.ran_node_count}"
  name = "${var.prefix}-ran${count.index + 1}.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_eip.ran-eip.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "rke" {
  zone_id = "${var.route53_zone_id}"
  name = "rke.${var.route53_subdomain}.${var.route53_domain}"
  type = "CNAME"
  ttl = "60"
  records = [aws_elb.rke-elb.dns_name]
}

#resource "aws_route53_record" "rancher" {
#  zone_id = "${var.route53_zone_id}"
#  name = "rancher.${var.route53_subdomain}.${var.route53_domain}"
#  type = "CNAME"
#  ttl = "60"
#  records = [aws_elb.rancher-elb.dns_name]
#}

resource "aws_route53_record" "rancher" {
  zone_id = "${var.route53_zone_id}"
  name = "rancher.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  alias {
    name = "${aws_elb.rancher-elb.dns_name}"
    zone_id = "${aws_elb.rancher-elb.zone_id}"
    evaluate_target_health = false
  }
}

