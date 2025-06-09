output "server_public_ip" {
  value = module.server.public_ip
}

output "client_public_ip" {
  value = module.client.public_ip
}
