provider "aws" {
  region     = "us-west-2"
  access_key = "AKIA4MBHVQUIOQCPWFQN"
  secret_key = "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"
}

# 1. Create Vpc

resource "aws_vpc" "prodvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = " production"
  }
}
# 2. Create iNternet gateway

resource "aws_internet_gateway" "gw"{
  vpc_id = aws_vpc.prodvpc.id

}



# 4. Create a Subnet

resource "aws_subnet" "subnet1"{
  vpc_id = aws_vpc.prodvpc.id

  cidr_block = "10.0.1.0/24"
  availability_zone ="us-west-2a"

  tags ={
     Name =  " prod-subnet"
     }
}

resource "aws_route_table" "prode"{
  vpc_id = aws_vpc.prodvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prode"
  }
}



  # 5. Associate subnet with route table

  resource "aws_route_table_association" "a"{
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.prode.id

  }
# 6. Create Security group to allow port 22, 80, 443

resource "aws_security_group" "allow" {
  name = " allow_web_traffic"
  description = "allow tls inbound traffic"
  vpc_id = aws_vpc.prodvpc.id
  
  ingress{

    description = "Https  "
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress{

    description = "Http  "
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{

    description = "SSH"
    from_port = 2
    to_port = 2
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

tags = {
  Name = " allow_web"
}
}
# 7. Create a Network interface with an ip in the subnet that was vreated in step 4

resource "aws_network_interface" "webservernic" {
  subnet_id = aws_subnet.subnet1.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.allow.id ]
}
# 8. Assign an elastic ip to the network interface created in step 7.

resource "aws_eip" one {
  vpc =true
  network_interface = aws_network_interface.webservernic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
#  9. Create Ubuntu server and install / enable apache2

resource "aws_instance" "ubuntu"{
  ami =  "ami-0ca5c3bd5a268e7db"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name= "mainkey"

  network_interface {
    device_index = 0 # first netwpork interface
    network_interface_id = aws_network_interface.webservernic.id
}

user_data = <<-EOF
#!/bin/bash
 sudo apt update -y
 sudo apt install apache2 -y
 sudo systemctl start apache2
 sudo bash -c 'echo your very first webserver > /var/www/html/index.html'

 EOF

 tags = {
    Name = "web-server"

 }
}




