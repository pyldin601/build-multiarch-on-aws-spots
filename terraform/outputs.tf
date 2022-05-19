output "private_key" {
  value     = tls_private_key.builder_key.private_key_pem
  sensitive = true
}

output "public_ips" {
  value     = [for spot in aws_spot_instance_request.spot : spot.public_ip]
  sensitive = false
}
