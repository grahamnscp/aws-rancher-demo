# elastic ips

# Associate Elastic IPs to Instances
resource "aws_eip" "cluster3-masters-eip" {

  count = "${var.cluster3_master_count}"
  instance = "${element(aws_instance.cluster3.*.id, count.index)}"

  tags = {
    Name = "${var.prefix}_cluster3-master${count.index + 1}"
  }

  depends_on = [aws_instance.cluster3]
}

resource "aws_eip" "cluster3-agents-eip" {

  count = "${var.cluster3_agent_count}"
  instance = "${element(aws_instance.cluster3-agents.*.id, count.index)}"

  tags = {
    Name = "${var.prefix}_cluster3-agent${count.index + 1}"
  }

  depends_on = [aws_instance.cluster3-agents]
}
