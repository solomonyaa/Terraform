
resource "aws_vpc" "my-vpc" {

  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-terra-vpc"
  }
}

resource "aws_subnet" "public-sub-1" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-sub-1"
  }
}

resource "aws_subnet" "public-sub-2" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "public-sub-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_route_table" "art" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-public-sub-1" {
  subnet_id      = aws_subnet.public-sub-1.id
  route_table_id = aws_route_table.art.id
}

resource "aws_route_table_association" "rta-public-sub-2" {
  subnet_id      = aws_subnet.public-sub-2.id
  route_table_id = aws_route_table.art.id
}
