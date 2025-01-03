# Output Values:


# Instances - cluster2
output "cluster2-instance-private-ips" {
  value = ["${aws_instance.cluster2.*.private_ip}"]
}
output "cluster2-instance-public-ips" {
  value = ["${aws_instance.cluster2.*.public_ip}"]
}
output "cluster2-instance-names" {
  value = ["${aws_route53_record.cluster2.*.name}"]
}
