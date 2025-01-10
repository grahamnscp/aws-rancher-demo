# Output Values:


# Instances - cluster3
output "cluster3-instance-private-ips" {
  value = ["${aws_instance.cluster3.*.private_ip}"]
}
output "cluster3-instance-public-ips" {
  value = ["${aws_instance.cluster3.*.public_ip}"]
}
output "cluster3-instance-names" {
  value = ["${aws_route53_record.cluster3.*.name}"]
}
