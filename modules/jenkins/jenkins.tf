# Define the variables used. These are set in the root module's terraform.tfvars file
variable "vpc_cidr_block" {}
variable "ingress_cidr_block" {}
variable "ami" {}
variable "instance_type" {}
variable "keyname" {}
variable "pk_location" {}
variable "hosted_zone" {}

# Create the VPC
resource "aws_vpc" "tf-jenkins" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"

  tags {
    Name = "TF - Jenkins - test"
  }
}

# Attach an Internet Gateway to the VPC
resource "aws_internet_gateway" "tf-jenkins-igw" {
  vpc_id = "${aws_vpc.tf-jenkins.id}"
  tags {
    name = "TF-Jenkins"
  }
}

# Read in the current route table for the newly created VPC
data "aws_route_table" "tf-jenkins-rt" {
  vpc_id = "${aws_vpc.tf-jenkins.id}"
}

# Add the internet route
resource "aws_route" "tf-jenkins-route" {
  route_table_id = "${data.aws_route_table.tf-jenkins-rt.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.tf-jenkins-igw.id}"
}

# Create the internal subnet
resource "aws_subnet" "tf-jenkins-subnet" {
  availability_zone = "us-east-1a"
  vpc_id = "${aws_vpc.tf-jenkins.id}"
  cidr_block = "${aws_vpc.tf-jenkins.cidr_block}"
  map_public_ip_on_launch = true
  tags {
    name = "TF-Jenkins"
  }
}

# Create a new security group and restrict ingress access
resource "aws_security_group" "tf-jenkins-sg"{
  name = "tf-jenkins"
  vpc_id = "${aws_vpc.tf-jenkins.id}"

  ingress {
  from_port = 22
  to_port = 22
  protocol = "TCP"
  cidr_blocks = ["${var.ingress_cidr_block}"]
  }
  ingress {
  from_port = 8080
  to_port = 8080
  protocol = "TCP"
  cidr_blocks = ["${var.ingress_cidr_block}"]
  }
  egress {
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy a single Jenkins Master and run an initial configuration playbook to set up Jenkins.
resource "aws_instance" "jenkins_master"{
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.keyname}"
  subnet_id = "${aws_subnet.tf-jenkins-subnet.id}"
  tags {
    Name = "TF-Jenkins"
  }
  vpc_security_group_ids = ["${aws_security_group.tf-jenkins-sg.id}"]
  provisioner "local-exec" {
   command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key '${var.pk_location}' -i '${aws_instance.jenkins_master.public_ip},' ../modules/jenkins/jenkins_install.yml"
  }

}

# Read in the current status of the Hosted Zone.
data "aws_route53_zone" "jenkins"{
  name = "${var.hosted_zone}"
}

# Add a CNAME record for Jenkins
resource "aws_route53_record" "jenkins" {
  zone_id = "${data.aws_route53_zone.jenkins.zone_id}"
  name = "jenkins.${data.aws_route53_zone.jenkins.name}"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_instance.jenkins_master.public_dns}"]

}
