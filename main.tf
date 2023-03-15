locals {
  vpc_id           = "vpc-0226d88c125c70d56"
  subnet_id        = "subnet-01257a0e0a54551f3"
  ssh_user         = "ec2-user"
  aws_ami          = "ami-0f1a5f5ada0e7da53"
  key_name         = "wordpress"
  private_key      = "/home/wordpress/Keys/wordpress.pem"
}
	
## If you use this under a different user, please adjust the path.

provider "aws" {
  region = "us-west-2"
  shared_credentials_files = ["/home/wordpress/.aws/credentials"]
}
	
resource "aws_security_group" "wordpress" {
  name = "wordpress_access"
  vpc_id = local.vpc_id
	
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
	
## You may need this sometime, but not for this demo.
## If this continued to develop, installing nginx/apache, and redirect
## port 80 to 8080.
#
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#  ingress {
#    from_port   = 8080
#    to_port     = 8080
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "wordpress" {
  ami                         = local.aws_ami
  subnet_id                   = local.subnet_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.wordpress.id]
  key_name                    = local.key_name
	
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key)
      timeout     = "5m"
      agent       = false
      host        = aws_instance.wordpress.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.wordpress.public_ip}, --private-key ${local.private_key} wordpress.yaml"
  }
}
	
output "wordpress_ip" {
  value = aws_instance.wordpress.public_ip
}
