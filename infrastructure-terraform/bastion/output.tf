output "fqdn" {
  value = local.fqdn
}

output "private-key" {
  value = tls_private_key.private_key.private_key_pem
}

output "ctl-secret" {
  value = random_password.ctl_secret.result
}
