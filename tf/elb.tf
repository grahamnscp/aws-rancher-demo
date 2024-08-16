# elb for rke2

resource "aws_elb" "rke-elb" {

  name = "${var.prefix}-rke-elb"

  subnets = [
   "${aws_subnet.dc-subnet1.id}",
   "${aws_subnet.dc-subnet2.id}",
   "${aws_subnet.dc-subnet3.id}"
  ]
  security_groups = [
    "${aws_security_group.dc-instance-sg.id}",
    "${aws_security_group.ran-lb-sg.id}",
  ]
  cross_zone_load_balancing = true

  listener {
    lb_port = 6443
    lb_protocol = "TCP"
    instance_port = 6443
    instance_protocol = "TCP"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:6443"
    interval = 10
  }

  instances = "${aws_instance.ran.*.id}"

  idle_timeout = 240
}
