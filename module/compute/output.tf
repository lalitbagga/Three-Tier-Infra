output "bastion_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}