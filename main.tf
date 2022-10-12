## How will it work?
## Create iam user that allows me ssh into the public server
## Modify the private instance security group to allow the public server to be able to ssh into the server.
## Open port 22 on the public server


/*
Resources to Create

1. AWS VPC Cloud
2. Internet Gateway
3. Public Subnet
4. Private Subnet
5. Route Table
6. Routes
7. 2 EC2 instances
8. Security groups

*/



resource "aws_vpc" "devcloud" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

}


resource "aws_internet_gateway" "devc_igw" {
  vpc_id = aws_vpc.devcloud.id
  tags = {
    Name = "DevC-IGW"
  }
  depends_on = [aws_vpc.devcloud]
}


resource "aws_subnet" "devc_public_subnet" {
  vpc_id                  = aws_vpc.devcloud.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "DevC-PublicSubnet"
  }
}

resource "aws_subnet" "devc_private_subnet" {
  vpc_id     = aws_vpc.devcloud.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "DevC-PrivateSubnet"
  }
}

resource "aws_route_table" "default_rtb" {
  vpc_id = aws_vpc.devcloud.id
  tags = {
    Names = "DefaultRTB"
  }
}

# resource "aws_route_table" "private_rtb" {
#   vpc_id = aws_vpc.devcloud.id
#   tags = {
#     Names = "PrivateRTB"
#   }
# }


resource "aws_route" "publicRoute" {
  route_table_id         = aws_route_table.default_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.devc_igw.id
}




# resource "aws_route" "privateRoute" {
#   route_table_id         = aws_route_table.private_rtb.id
#   destination_cidr_block = "10.0.1.0/24"
#   gateway_id = "local"
# }

resource "aws_route_table_association" "devcPublicAssociation" {
  subnet_id      = aws_subnet.devc_public_subnet.id
  route_table_id = aws_route_table.default_rtb.id
}

# resource "aws_route_table_association" "devcPrivateAssociation" {
#   subnet_id      = aws_subnet.devc_private_subnet.id
#   route_table_id = aws_route_table.private_rtb.id
# }
resource "aws_key_pair" "devc_auth" {
  key_name   = "devc_auth"
  public_key = file("./devc.txt")
}

resource "aws_instance" "private_instance" {
  ami                         = data.aws_ami.devc_data_source.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.devc_private_subnet.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  key_name                    = "jumpbox"


}

resource "aws_instance" "public_instance" {
  ami                         = data.aws_ami.devc_data_source.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.devc_public_subnet.id
  key_name                    = aws_key_pair.devc_auth.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true

  }




resource "aws_security_group" "public_sg" {
  name        = "DevC Public SG"
  description = "Allow connections from my computer via ssh"
  vpc_id      = aws_vpc.devcloud.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_security_group" "private_sg" {
  name        = "DevC Private SG"
  description = "Allow connections from resources only in the public subnet"
  vpc_id      = aws_vpc.devcloud.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

