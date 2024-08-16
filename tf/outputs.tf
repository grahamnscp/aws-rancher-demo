# Output Values:

# Domain
output "domainname" {
  value = "${var.route53_subdomain}.${var.route53_domain}"
}

# Instances - ran
output "ran-instance-private-ips" {
  value = ["${aws_instance.ran.*.private_ip}"]
}
output "ran-instance-public-eips" {
  value = ["${aws_eip.ran-eip.*.public_ip}"]
}
output "ran-instance-names" {
  value = ["${aws_route53_record.ran.*.name}"]
}
