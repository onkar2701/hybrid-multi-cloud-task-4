provider "aws" {
  region = "ap-south-1"
  profile = "onkar"
}

resource "aws_vpc" "vpc1" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "om-vpc"
  }
}


resource "aws_subnet" "sub-1a" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "192.168.0.0/24"
  availability_zone= "ap-south-1a"
  map_public_ip_on_launch ="true"

  tags = {
    Name = "om-sub-1"
  }
}

resource "aws_subnet" "sub-1b" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "192.168.1.0/24"
  availability_zone= "ap-south-1b"
  map_public_ip_on_launch ="false"
  tags = {
    Name = "om-sub-2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "om-gw"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "om-route-table"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.sub-1a.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sg1" {
name        = "allow_http_ssh_icmp"
vpc_id     = aws_vpc.vpc1.id
ingress {
    description = "Allow_http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "Allow_icmp"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "Allow_ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allow_http_icmp_ssh"
  }
}

resource "aws_security_group" "sg2" {
name        = "allow_mysql"
vpc_id     = aws_vpc.vpc1.id
ingress {
    description = "Allow_mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allow_mysql"
  }
}


resource "aws_security_group" "sg3" {
name        = "allow_bastion_os"
vpc_id     = aws_vpc.vpc1.id
ingress {
    description = "Allow_ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allow_bastion_os"
  }
}

resource "aws_security_group" "sg4" {
name        = "allow_mysql_database"
vpc_id     = aws_vpc.vpc1.id
ingress {
    description = "Allow_ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups= [aws_security_group.sg3.id]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allow_mysql_database"
  }
}


resource "aws_instance" "WP" {
   ami          = "ami-7e257211"
   instance_type= "t2.micro"
   key_name     = "cloud-task"
   vpc_security_group_ids = [aws_security_group.sg1.id]
   subnet_id    = aws_subnet.sub-1a.id
   
      tags ={
          Name = "WORDPRESS"
     }
}


resource "aws_instance" "MYSQL" {
   ami          = "ami-08706cb5f68222d09"
   instance_type= "t2.micro"
   key_name     = "cloud-task"
   vpc_security_group_ids = [aws_security_group.sg2.id,aws_security_group.sg4.id]
   subnet_id    = aws_subnet.sub-1b.id
   
      tags ={
          Name = "MYSQL"
     }
}

resource "aws_instance" "Bastion_instance" {
   ami          = "ami-0732b62d310b80e97"
   instance_type= "t2.micro"
   key_name     = "cloud-task"
   vpc_security_group_ids = [aws_security_group.sg3.id]
   subnet_id    = aws_subnet.sub-1a.id
   
      tags ={
          Name = "BASTION"
     }
}


