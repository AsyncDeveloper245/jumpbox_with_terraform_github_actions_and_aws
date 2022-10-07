output "PublicIp" {
  value = aws_instance.public_instance.public_ip
}

output "PrivateIp"{
    value = aws_instance.private_instance.private_ip
}