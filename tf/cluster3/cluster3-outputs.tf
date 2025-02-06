# Output Values:


# Instances - cluster3
# masters:
output "cluster3-instance-private-ips" {
  value = ["${aws_instance.cluster3.*.private_ip}"]
}
output "cluster3-instance-public-ips" {
  value = ["${aws_eip.cluster3-masters-eip.*.public_ip}"]
}
output "cluster3-instance-names" {
  value = ["${aws_route53_record.cluster3.*.name}"]
}

# agents:
output "cluster3-instance-agent-private-ips" {
  value = ["${aws_instance.cluster3-agents.*.private_ip}"]
}
output "cluster3-instance-agent-public-ips" {
  value = ["${aws_eip.cluster3-agents-eip.*.public_ip}"]
}
output "cluster3-instance-agent-names" {
  value = ["${aws_route53_record.cluster3-agents.*.name}"]
}
