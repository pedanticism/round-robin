# Create a new instance of the latest Ubuntu 14.04 on an
# t2.micro node with an AWS Tag naming it "HelloWorld"

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web_instance1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_default_subnet.default_az1.id
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = "RoundRobin"
  }
}
resource "aws_instance" "web_instance2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_default_subnet.default_az2.id
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = "RoundRobin"
  }
}


resource "aws_iam_role" "role" {
  name = "instance_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_CloudWatchAgentServerPolicy" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.role.name
}


# TODO Create and attach instance role for SSM access to the instances so I can look to install the node runtimes.
# TODO Define instance metdata to install node JS, upload the code and start the runtime
# TODO confugure cloudwatch logging
# TODO Security groups