# security-lb

resource "aws_security_group" "cluster1-lb-sg" {

  name = "${var.prefix}-cluster1_lb_sg-${random_string.suffix.result}"
  description = "Security Group for cluster1 LB"

  tags = {
    Name = "${var.prefix}_cluster1_lb_sg"
  }

  vpc_id = "${aws_vpc.dc-vpc.id}"

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

  # open 443 for downstream clusters to reach public dns address
  ingress {
    description = "All 443"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # open 8089 - cert-manager
  ingress {
    description = "All 8089"
    from_port = 8089
    to_port = 8089
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # open otel ports
  ingress {
    description = "All 8888"
    from_port = 8888
    to_port = 8888
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "All 4317"
    from_port = 4317
    to_port = 4317
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "All 4318"
    from_port = 4318
    to_port = 4318
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "All 80"
    from_port = 80
    to_port = 80
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

