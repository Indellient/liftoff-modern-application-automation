output "fqdn" {
  value = format("https://%s", local.fqdn)
}

output "private-key" {
  value = tls_private_key.private_key.private_key_pem
}

output "password" {
  value = random_password.password.result
}
