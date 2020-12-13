resource "aws_iam_role" "this" {
  name = "${var.project}-${var.env}"

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
  tags = {
      project = var.project
      env     = var.env
  }
}

resource "aws_iam_role_policy" "this" {
  name = "${var.project}-${var.env}"
  role = aws_iam_role.this.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*",
        "cloudwatch:*",
        "ec2:*",
        "ssm:*",
        "ssmmessages:*",
        "ec2messages:*",
        "elasticloadbalancing:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project}-${var.env}"
  role = aws_iam_role.this.id
}

resource "aws_security_group" "this" {
  name_prefix = "${var.project}-${var.env}"
  description = "virtual firewall that controls the traffic"
  vpc_id      = module.vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle  {
    create_before_destroy = true
  }
}