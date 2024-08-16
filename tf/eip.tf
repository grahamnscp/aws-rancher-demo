# elastic ips

# Associate Elastic IPs to Instances
resource "aws_eip" "ran-eip" {

  count = "${var.ran_node_count}"
  instance = "${element(aws_instance.ran.*.id, count.index)}"

  tags = {
    Name = "${var.prefix}_ran${count.index + 1}"
  }

  depends_on = [aws_instance.ran]
}
