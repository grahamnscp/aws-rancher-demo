# elb for rancher

resource "aws_elb" "cluster2-elb" {

  name = "${var.prefix}-cluster2-elb"

  subnets = [
    "${aws_subnet.dc-subnet1.id}",
    "${aws_subnet.dc-subnet2.id}",
    "${aws_subnet.dc-subnet3.id}"
  ]
  security_groups = [
    "${aws_security_group.dc-instance-sg.id}",
    "${aws_security_group.cluster2-lb-sg.id}",
  ]
  cross_zone_load_balancing = true

  # tcp - pass https traffic through
  listener {
    lb_port = 443
    lb_protocol = "tcp"
    instance_port = 443
    instance_protocol = "tcp"
  }
  listener {
    lb_port = 80
    lb_protocol = "tcp"
    instance_port = 80
    instance_protocol = "tcp"
  }
  # for cert-manager verifications
  listener {
    lb_port = 8089
    lb_protocol = "tcp"
    instance_port = 8089
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:6443"
    interval = 10
  }

  instances = "${aws_instance.cluster2.*.id}"

  idle_timeout = 240
}
