# security-lb

resource "aws_security_group" "ran-lb-sg" {

  name = "${var.prefix}-ran_lb_sg-${random_string.suffix.result}"
  description = "Security Group for Rancher LB"

  tags = {
    Name = "${var.prefix}_ran_lb_sg"
  }

  vpc_id = "${aws_vpc.dc-vpc.id}"

  # allow rancher node instance security group
#  ingress {
#    description = "Instance SG"
#    from_port = 0
#    to_port = 0
#    protocol = "-1"
#    security_groups = [ aws_security_group.dc-instance-sg.id ]
#  }

  # allow self
  ingress {
    description = "Self"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  # allow all for internal subnet
  ingress {
    description = "Internal VPC"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["172.20.0.0/16"]
  }

  # open all for specific ips
  ingress {
    description = "Allow IPs"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.ip_cidr_me}","${var.ip_cidr_work}"]
  }

  # open 443
  ingress {
    description = "All 443"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # open 8089
  ingress {
    description = "All 8089"
    from_port = 8089
    to_port = 8089
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # egress out for all
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

