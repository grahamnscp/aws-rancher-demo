# Security Groups:

resource "aws_security_group" "dc-instance-sg" {
  name = "${var.prefix}-dc_instance_sg-${random_string.suffix.result}"

  tags = {
    Name = "${var.prefix}_instance_sg"
  }
  vpc_id = "${aws_vpc.dc-vpc.id}"

  # allow all ping
  ingress {
    description = "All Ping"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all self (tcp & udp)
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


  # egress out for all
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

