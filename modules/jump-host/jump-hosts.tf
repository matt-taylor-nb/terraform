# Define variables. These are set in the root module's terraform.tfvars file
variable "vpc_cidr_block" {}
variable "ingress_cidr_block" {}
variable "ami" {}
variable "instance_type" {}
variable "keyname" {}
variable "hosted_zone" {}

# Create the new VPC for the jump hosts
resource "aws_vpc" "tf-jump-hosts" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "TF - Jump Hosts"
  }
}

# Attach an IGW to the VPC
resource "aws_internet_gateway" "tf-jump-hosts-igw" {
  vpc_id = "${aws_vpc.tf-jump-hosts.id}"
  tags {
    name = "TF-Jump-Hosts"
  }
}

# Read the state of the VPC route table
data "aws_route_table" "tf-jump-hosts-rt" {
  vpc_id = "${aws_vpc.tf-jump-hosts.id}"
}

# ammend the route table
resource "aws_route" "tf-jump-hosts-route" {
  route_table_id = "${data.aws_route_table.tf-jump-hosts-rt.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.tf-jump-hosts-igw.id}"
}

# Create the new internal subnet
resource "aws_subnet" "tf-jump-hosts-subnet" {
  availability_zone = "us-east-1a"
  vpc_id = "${aws_vpc.tf-jump-hosts.id}"
  cidr_block = "${aws_vpc.tf-jump-hosts.cidr_block}"
  map_public_ip_on_launch = true
  tags {
    name = "TF-Jump-Hosts"
  }

}

# Create the security group and restrict the origin of SSH traffic
resource "aws_security_group" "tf-jump-hosts-sg"{
  name = "tf-jump-hosts"
  description = "All SSH inbound"
  vpc_id = "${aws_vpc.tf-jump-hosts.id}"

  ingress {
  from_port = 22
  to_port = 22
  protocol = "TCP"
  cidr_blocks = ["${var.ingress_cidr_block}"]
  }
  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the instance
resource "aws_instance" "jump-hosts"{
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.keyname}"
  subnet_id = "${aws_subnet.tf-jump-hosts-subnet.id}"
  tags {
    Name = "TF-Jump Hosts"
  }
  vpc_security_group_ids = ["${aws_security_group.tf-jump-hosts-sg.id}"]

}

# Read the current state of the Route 53 hosted zone
data "aws_route53_zone" "default"{
  name = "${var.hosted_zone}"
}

# Add a CNAME entry for the jump host
resource "aws_route53_record" "jump-hosts" {
  zone_id = "${data.aws_route53_zone.default.zone_id}"
  name = "jump.${data.aws_route53_zone.default.name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_instance.jump-hosts.public_dns}"]

}
