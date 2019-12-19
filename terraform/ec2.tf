# Create a new instance of the latest Ubuntu 14.04 on an
# t2.micro node with an AWS Tag naming it "HelloWorld"

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["round-robin/Ubuntu-bionic-amd64-*"]
  }
  owners=[441546210005]
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

resource "aws_iam_instance_profile" "round_robin" {
  name = "instance_profile"
  role = aws_iam_role.role.name
}


resource "aws_launch_template" "round_robin" {
  name_prefix   = "round_robin"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  iam_instance_profile { 
    arn=aws_iam_instance_profile.round_robin.arn
  }
  vpc_security_group_ids=[aws_default_security_group.default_sg.id]
}

resource "aws_autoscaling_group" "round_robin" {
  name               = "asg_round_robin"
  availability_zones = ["eu-west-1a","eu-west-1b"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2
  target_group_arns   = [aws_alb_target_group.alb_target_group.arn]
  launch_template {
    id      = aws_launch_template.round_robin.id
    version = aws_launch_template.round_robin.latest_version
  }
}