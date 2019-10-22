output "fqdn" {
  value = format("https://%s", local.fqdn)
}
