# elb for rancher

resource "aws_elb" "cluster1-elb" {

  name = "${var.prefix}-cluster1-elb"

  subnets = [
    "${aws_subnet.dc-subnet1.id}",
    "${aws_subnet.dc-subnet2.id}",
    "${aws_subnet.dc-subnet3.id}"
  ]
  security_groups = [
    "${aws_security_group.dc-instance-sg.id}",
    "${aws_security_group.cluster1-lb-sg.id}",
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
  # for suse-observability remote receivers
  listener {
    lb_port = 7070
    lb_protocol = "tcp"
    instance_port = 7070
    instance_protocol = "tcp"
  }
  listener {
    lb_port = 7077
    lb_protocol = "tcp"
    instance_port = 7077
    instance_protocol = "tcp"
  }
  # for suse-observability otel receivers
  listener {
    lb_port = 8888
    lb_protocol = "tcp"
    instance_port = 8888
    instance_protocol = "tcp"
  }
  listener {
    lb_port = 4317
    lb_protocol = "tcp"
    instance_port = 4317
    instance_protocol = "tcp"
  }
  listener {
    lb_port = 4318
    lb_protocol = "tcp"
    instance_port = 4318
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:6443"
    interval = 10
  }

  instances = "${aws_instance.cluster1.*.id}"

  idle_timeout = 240
}
