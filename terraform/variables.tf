variable "docker_login" {}

variable "docker_password" {}

variable "aws_ec2_key_pair_name" {
  default = "spot-key-pair"
}

variable "aws_ec2_security_group_name" {
  default = "spot-security-group"
}

variable "aws_ec2_instance_size" {
  default = "xlarge"
}

variable "aws_region" {
  default = "eu-central-1"
}
