
data "aws_ami" "linux2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer_key"
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj+r0LNfIZBTZbPTfBRArRmQhGcxs2OLpgHV+VRh9LUK5wq9OXefsdeub5adJ8Yq9DXVbhw2P3/H6DhSokXMKx7A8FG1ta11hukA7kC/8bwgQP4hHrLjd1e1JCRev96mJ1EsiZ6LcPltolXthI4nBzCeZiBoQMLEMmXzsxl1MljQUzXZsVy+e4a3om3eIkJ6LhtmgWw0j7zxiwZcNZpZdNO+kGGsR1eTdYO0Riui9W4rwauje1p0hCuukbeSlhLKdx42LlOeohG+ZyJsfhReI7JjdT6qnWD7al4u9NsuBw2Tw0WfGW5FXWlbzRGo7UdMDaMn/avAQepC4rgcenrZYAa9sl+mMQ4NaU0ThCeLHk7KIGEl3RDCoOnR2MlYA1hMuFaJOzf9Pm/M6RihWojLbmpcX5LrurDrTHgfQ+qqUlfbB2d/mY4vUkGVerFTB5V4WN8lKGJYYj/A16F2mQIofSyla3WCsAMggOOON4ZMifa0h2QEbPaM/h/TvwSMt0FQk= pomidor@Alexeys-MBP.hsd1.ga.comcast.net"
  public_key = var.public_key
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.linux2023.id
  subnet_id     = data.aws_subnets.subnets.ids[0]
  instance_type = var.instance_type
  key_name = "${aws_key_pair.deployer.key_name}"
  vpc_security_group_ids = [aws_security_group.sg_my_server.id]
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = var.server_name
  }
}

data "template_file" "user_data" {
    template = file("${abspath(path.module)}/userdata.yaml")
}

resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "My Server SG"
  vpc_id      = data.aws_vpc.main.id

  ingress = [{
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self = false
  },
  {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self = false
  }]

  egress = [{
    description     = "Outgoing"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self = false
  }]
}