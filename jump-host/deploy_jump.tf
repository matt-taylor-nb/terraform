variable "access_key" {}
variable "secret_key" {}
variable "region" {}

variable "vpc_cidr_block" {}
variable "ingress_cidr_block" {}
variable "ami" {}
variable "instance_type" {}
variable "keyname" {}
variable "hosted_zone" {}

# Configure the AWS Provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "jump-host" {
  source = "../modules/jump-host"
  vpc_cidr_block = "${var.vpc_cidr_block}"
  ingress_cidr_block = "${var.ingress_cidr_block}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  keyname = "${var.keyname}"
  hosted_zone = "${var.hosted_zone}"
}
