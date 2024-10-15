# Output Values:


# Instances - cluster1
output "cluster1-instance-private-ips" {
  value = ["${aws_instance.cluster1.*.private_ip}"]
}
output "cluster1-instance-public-ips" {
  value = ["${aws_instance.cluster1.*.public_ip}"]
}
output "cluster1-instance-names" {
  value = ["${aws_route53_record.cluster1.*.name}"]
}
