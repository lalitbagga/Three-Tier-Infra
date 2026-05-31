locals {
  cloudwatch_user_data = <<-EOF
    #!/bin/bash

    yum update -y
    yum install -y amazon-cloudwatch-agent

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 \
      -c ssm:/cloudwatch-agent/config \
      -s
  EOF
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ec2_role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

//store the config in SSM:
resource "aws_ssm_parameter" "cloudwatch_config" {
  name = "/cloudwatch-agent/config"
  type = "String"
  value = jsonencode({
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/messages"
              log_group_name  = "ec2-logs"
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file("~/.ssh/bastion-key.pub")
}

//Create ec2 instance for bastion host
resource "aws_instance" "bastion_host" {
  ami                         = "ami-0278a2977a50e13fc" // Amazon Linux 2 AMI 
  instance_type               = "t3.micro"
  subnet_id                   = var.main_subnet_public_1_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_key.key_name
  tags = {
    Name = "bastion_host"
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = local.cloudwatch_user_data
}

//Setup for private instance


resource "aws_instance" "private_host" {
  ami                         = "ami-0278a2977a50e13fc" // Amazon Linux 2 AMI 
  instance_type               = "t3.micro"
  subnet_id                   = var.main_subnet_private_1_id
  vpc_security_group_ids      = [var.private_sg_id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.bastion_key.key_name
  tags = {
    Name = "private_host"
  }
}

