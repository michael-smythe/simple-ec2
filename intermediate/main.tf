provider "aws" {
  region                  = "us-east-2"
}

# TRUSTED KEY PAIR FOR DEPLOYMENT
resource "aws_key_pair" "build_key" {
  key_name        = "build_key"
  public_key      = "ssh-rsa AAAAB3NzaC1yc"
}

resource "aws_vpc" "vpc" {
  cidr_block                    = "10.0.0.0/16"
}

# INTERNET GATEWAY FOR THE VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

# ROUTING TABLE ENTRY THAT PUSHES ALL TRAFFIC TO THE INTERNET
resource "aws_route_table" "pub" {
  vpc_id          = aws_vpc.vpc.id
  route {
    cidr_block    = "0.0.0.0/0"
    gateway_id    = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "pub" {
  subnet_id         = aws_subnet.builder.id 
  route_table_id    = aws_route_table.pub.id
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_subnet" "builder" {
  vpc_id                        = aws_vpc.vpc.id
  map_public_ip_on_launch       = "true"
  cidr_block                    = "10.0.0.0/24"
}

resource "aws_security_group" "pub" {
  vpc_id                      = aws_vpc.vpc.id

  ingress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = ["0.0.0.0/0"]

  }

  egress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "key"
  private_ip                    = "10.0.0.10"

  subnet_id                     = aws_subnet.builder.id
  security_groups               = [aws_security_group.pub.id]

  connection {
    type            = "ssh"    
    user            = "ubuntu"    
    private_key     = file("/PATH/TO/SSH/key")
    host            = aws_instance.ec2.public_ip
  }

  provisioner "remote-exec" {
      # run commands that you want to here
      inline = [
          "sudo apt update",
          "sudo apt upgrade -y"
      ]
  }
}
