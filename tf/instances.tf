# Instances:

# Rancher Cluster Instances:
#
resource "aws_instance" "ran" {

  instance_type = "${var.aws_instance_type_ran}"
  ami           = "${var.aws_ami}"
  key_name      = "${var.aws_key_name}"

  root_block_device {
    volume_size = "${var.volume_size_ran}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  iam_instance_profile = "${aws_iam_instance_profile.rancher_instance_profile.id}"

  vpc_security_group_ids = ["${aws_security_group.dc-instance-sg.id}"]
  subnet_id = "${aws_subnet.dc-subnet1.id}"

  user_data = "${file("userdata.sh")}"

  count = "${var.ran_node_count}"

  tags = {
    Name = "${var.prefix}_ran${count.index + 1}"
  }
}

