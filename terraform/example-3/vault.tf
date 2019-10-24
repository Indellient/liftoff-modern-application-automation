provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

data "vault_generic_secret" "grafana" {
  path = "secret/indellient/hashicorp-sales-demo/grafana"
}
