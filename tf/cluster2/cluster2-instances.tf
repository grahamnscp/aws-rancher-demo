# Instances:

# Downstream Cluster Nodes
#
resource "aws_instance" "cluster2" {

  instance_type = "${var.aws_instance_type_cluster2}"
  ami           = "${var.aws_ami}"
  key_name      = "${var.aws_key_name}"

  root_block_device {
    volume_size = "${var.volume_size_cluster2}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  # second disk
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "${var.volume_size_second_disk_cluster2}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  # third disk (needed if using portworx)
  #ebs_block_device {
  #  device_name = "/dev/sdc"
  #  volume_size = "${var.volume_size_third_disk_cluster2}"
  #  volume_type = "gp2"
  #  delete_on_termination = true
  #}

  iam_instance_profile = "${aws_iam_instance_profile.rancher_instance_profile.id}"

  vpc_security_group_ids = ["${aws_security_group.dc-instance-sg.id}"]
  subnet_id = "${aws_subnet.dc-subnet1.id}"

  user_data = "${file("cluster2-userdata.sh")}"

  count = "${var.cluster2_node_count}"

  tags = {
    Name = "${var.prefix}-cluster2-${count.index + 1}"
  }
}

