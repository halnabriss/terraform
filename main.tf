terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.48.0"
    }
  }
}

#AWS Provider

provider "aws" {
  # Configuration options
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Create dedicated VPC and subnet
resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"   
    tags = {
        Name = "prod-vpc"
    }
}

resource "aws_internet_gateway" "prod-igw" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    tags = {
        Name = "prod-igw"
    }
}


resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.prod-vpc.id
route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-igw.id
    }
tags = {
        Name = "Public Subnet Route Table"
    }
}
resource "aws_route_table_association" "rt_associate_public" {
    subnet_id = aws_subnet.prod-subnet-01.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt_associate_public02" {
    subnet_id = aws_subnet.prod-subnet-02.id
    route_table_id = aws_route_table.rt.id
}




resource "aws_subnet" "prod-subnet-01" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone_id = "use1-az1"
    tags = {
        Name = "prod-subnet-01"
    }
}


resource "aws_subnet" "prod-subnet-02" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone_id = "use1-az2"
    tags = {
        Name = "prod-subnet-02"
    }
}


resource "aws_instance" "websrv01" {
  ami           = "ami-07caf09b362be10b8"
  instance_type="t2.micro"
  subnet_id = "${aws_subnet.prod-subnet-01.id}"
  user_data = <<EOF
#!/bin/bash
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo "server01" > /var/www/html/index.html
touch /tmp/server01
EOF
  tags = {
Name = "websrv01"
  }
}

resource "aws_instance" "websrv02" {
ami           = "ami-07caf09b362be10b8"
  instance_type="t2.micro"
  subnet_id = "${aws_subnet.prod-subnet-01.id}"
  
  user_data = <<EOF
#!/bin/bash
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo "server02" > /var/www/html/index.html
touch /tmp/server02
EOF
  tags = {
Name = "websrv02"
  }
}

resource "aws_instance" "websrv03" {
  ami           = "ami-07caf09b362be10b8"
  instance_type="t2.micro"
  subnet_id = "${aws_subnet.prod-subnet-01.id}"
  
  user_data = <<EOF
#!/bin/bash
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo "server03" > /var/www/html/index.html
touch /tmp/server03
EOF
  tags = {
Name = "websrv03"
  }
}


resource "aws_network_interface_sg_attachment" "sg_attachment_w01" {
  security_group_id    = "${aws_security_group.web_sg.id}"
  network_interface_id = "${aws_instance.websrv01.primary_network_interface_id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_w02" {
  security_group_id    = "${aws_security_group.web_sg.id}"
  network_interface_id = "${aws_instance.websrv02.primary_network_interface_id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment_w03" {
  security_group_id    =  "${aws_security_group.web_sg.id}"
  network_interface_id = "${aws_instance.websrv03.primary_network_interface_id}"
}





resource "aws_security_group" "web_sg" {
vpc_id      = "${aws_vpc.prod-vpc.id}"
# Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}





resource "aws_lb" "app-lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.web_sg.id}"]
  subnets            = ["${aws_subnet.prod-subnet-01.id}" , "${aws_subnet.prod-subnet-02.id}"]

}


resource "aws_lb_target_group" "my_tg" { // Target Group A
 name     = "my-target-group"
 port     = 80
 protocol = "HTTP"
 vpc_id   = "${aws_vpc.prod-vpc.id}"

}

resource "aws_lb_target_group_attachment" "tg_attachment_01" {
 target_group_arn = "${aws_lb_target_group.my_tg.arn}"
 target_id        = "${aws_instance.websrv01.id}"
 port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_02" {
 target_group_arn = "${aws_lb_target_group.my_tg.arn}"
 target_id        = "${aws_instance.websrv02.id}"
 port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_03" {
 target_group_arn = "${aws_lb_target_group.my_tg.arn}"
 target_id        = "${aws_instance.websrv03.id}"
 port             = 80
}


resource "aws_lb_listener" "my_alb_listener" {
 load_balancer_arn = "${aws_lb.app-lb.arn}"
 port              = "80"
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = "${aws_lb_target_group.my_tg.arn}"
 }
}

