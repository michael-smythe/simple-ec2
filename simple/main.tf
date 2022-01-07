terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Credentials can be passed via enviornment variables, ~/.aws/credentials file, or explicity in this provider (not recommended)
# This will build in the default VPC associated with your account information.
provider "aws" {
  region = "us-east-2"
}

# Load SSH Keys - or use data "aws_key_pair" if you already have a loaded key on amazon
resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = file("/PATH/TO/SSH/key.pub")
}

# Instances
# What type of ami do you want to deploy
data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "key"

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