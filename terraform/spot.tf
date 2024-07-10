variable "environment" {
  type = map(object({
    arch : string,
    instance_type : string
  }))
  default = {
    amd64 = {
      arch : "x86_64",
      instance_type : "c5"
    },
    arm64 = {
      arch : "arm64",
      instance_type : "c6g"
    }
  }
}

data "aws_ami" "builder" {
  for_each = var.environment

  most_recent = true

  filter {
    name   = "architecture"
    values = [each.value.arch]
  }

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*-server-*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "tls_private_key" "builder_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "spot_key" {
  key_name   = var.aws_ec2_key_pair_name
  public_key = tls_private_key.builder_key.public_key_openssh
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_default_vpc.default.id
  name   = var.aws_ec2_security_group_name

  ingress {
    description      = "SSH from Github Action"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_spot_instance_request" "spot" {
  for_each = var.environment

  ami           = data.aws_ami.builder[each.key].id
  instance_type = "${each.value.instance_type}.${var.aws_ec2_instance_size}"

  associate_public_ip_address = true
  wait_for_fulfillment        = true
  spot_type                   = "one-time"

  key_name               = aws_key_pair.spot_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  root_block_device {
    volume_size = "16"
  }

  tags = {
    Name = "DockerBuilder"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = tls_private_key.builder_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      // Initialize and install docker
      "sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg lsb-release git",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io",

      // Authenticate on the Docker Hub
      "sudo docker login -u=\"${var.docker_login}\" -p=\"${var.docker_password}\"",
    ]
  }
}
