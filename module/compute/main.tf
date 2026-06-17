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

# EBS volume for persistent storage
resource "aws_ebs_volume" "monitoring" {
  availability_zone = "us-east-2a"
  size              = 20
  type              = "gp3"

  tags = {
    Name = "monitoring-data"
  }
}

# EC2 instance for Prometheus and Grafana
resource "aws_instance" "monitoring" {
  ami                    = "ami-0f0ce06b5a8a31018"
  instance_type          = "t3.micro"
  subnet_id              = var.main_subnet_public_1_id
  vpc_security_group_ids = [var.monitoring_sg_id]
  key_name               = aws_key_pair.bastion_key.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create prometheus config
    mkdir -p /monitoring
    cat <<CONFIG > /monitoring/prometheus.yml
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'three-tier-app'
        static_configs:
          - targets: ['${var.alb_dns_name}']
        metrics_path: '/metrics'
    CONFIG

    # Create docker compose file
    cat <<COMPOSE > /monitoring/docker-compose.yml
    version: '3'
    services:
      prometheus:
        image: prom/prometheus
        ports:
          - "9090:9090"
        volumes:
          - ./prometheus.yml:/etc/prometheus/prometheus.yml
          - prometheus-data:/prometheus

      grafana:
        image: grafana/grafana
        ports:
          - "3000:3000"
        environment:
          - GF_SECURITY_ADMIN_PASSWORD=admin123
        volumes:
          - grafana-data:/var/lib/grafana

    volumes:
      prometheus-data:
      grafana-data:
    COMPOSE

    # Start everything
    cd /monitoring
    docker-compose up -d
  EOF

  tags = {
    Name = "monitoring"
  }
}

# Attach EBS to EC2
resource "aws_volume_attachment" "monitoring" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.monitoring.id
  instance_id = aws_instance.monitoring.id
}

