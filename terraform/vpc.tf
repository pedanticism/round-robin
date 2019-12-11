
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
    Author = "SPC"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Default subnet for eu-west-1a"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "eu-west-1b"

  tags = {
    Name = "Default subnet for eu-west-1b"
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 80
    description = "Inbound HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ALB SG egress rule"
  }
}
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 80
    description = "Inbound HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    protocol  = "tcp"
    self      = true
    from_port = 3000
    to_port   = 3000
    description = "Inbound HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default SG egress rule"
  }
}