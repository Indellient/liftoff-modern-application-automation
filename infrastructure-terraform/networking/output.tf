output "public_subnet_id" {
  value = azurerm_subnet.public.id
}

output "dns_zone_name" {
  value = azurerm_dns_zone.dns_zone.name
}
