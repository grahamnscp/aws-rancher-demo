# vpc.tf

# VPC
resource "aws_vpc" "dc-vpc" {
  cidr_block           = "${var.vpcCIDRblock}"
  instance_tenancy     = "${var.instanceTenancy}"
  enable_dns_support   = "${var.dnsSupport}"
  enable_dns_hostnames = "${var.dnsHostNames}"

  tags = {
    Name = "${var.prefix}_vpc_${random_string.suffix.result}"
  }
}

# Subnets
resource "aws_subnet" "dc-subnet1" {
  vpc_id                  = "${aws_vpc.dc-vpc.id}"
  cidr_block              = "${var.subnet1CIDRblock}"
  map_public_ip_on_launch = "${var.mapPublicIP}"

  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.prefix}_subnet1_${random_string.suffix.result}"
  }
}
resource "aws_subnet" "dc-subnet2" {
  vpc_id                  = "${aws_vpc.dc-vpc.id}"
  cidr_block              = "${var.subnet2CIDRblock}"
  map_public_ip_on_launch = "false"

  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.prefix}_subnet2_${random_string.suffix.result}"
  }
}
resource "aws_subnet" "dc-subnet3" {
  vpc_id                  = "${aws_vpc.dc-vpc.id}"
  cidr_block              = "${var.subnet3CIDRblock}"
  map_public_ip_on_launch = "false"

  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.prefix}_subnet3_${random_string.suffix.result}"
  }
}
# WIP public subnets
#resource "aws_subnet" "dc-subnets" {
#  count = "${length(var.subnetCIDRspublic)}"
#
#  vpc_id = "${aws_vpc.dc-vpc.id}"
#  cidr_block = "${var.subnetCIDRspublic[count.index]}"
#  availability_zone = "${var.availability_zones[count.index]}"
#}

# Gateway
resource "aws_internet_gateway" "dc-gateway" {
  vpc_id = "${aws_vpc.dc-vpc.id}"

  tags = {
    Name = "${var.prefix}_gateway_${random_string.suffix.result}"
  }
}

# Route
resource "aws_route_table" "dc-route" {
  vpc_id = "${aws_vpc.dc-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dc-gateway.id}"
  }

  tags = {
    Name = "${var.prefix}_route_${random_string.suffix.result}"
  }
}

# WIP Associate Route to Subnets
#resource "aws_route_table_association" "dc-subnet-route" {
#  count = "${length(var.subnetCIDRspublic}"
#
#  subnet_id      = "${aws_subnet.dc-subnet.id}"
#  subnet_id      = "${element(aws_subnet.dc-subnets.*.id, count.index)}"
#  route_table_id = "${aws_route_table.dc-route.id}"
#}
resource "aws_route_table_association" "dc-subnet1-route" {
  subnet_id      = "${aws_subnet.dc-subnet1.id}"
  route_table_id = "${aws_route_table.dc-route.id}"
}
resource "aws_route_table_association" "dc-subnet2-route" {
  subnet_id      = "${aws_subnet.dc-subnet2.id}"
  route_table_id = "${aws_route_table.dc-route.id}"
}
resource "aws_route_table_association" "dc-subnet3-route" {
  subnet_id      = "${aws_subnet.dc-subnet3.id}"
  route_table_id = "${aws_route_table.dc-route.id}"
}

