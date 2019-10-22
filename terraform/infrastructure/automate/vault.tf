provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

data "vault_generic_secret" "automate_license" {
  path = "secret/indellient/hashicorp-sales-demo/automate"
}

resource "vault_generic_secret" "automate" {
  path = "secret/indellient/hashicorp-sales-demo/automate"

  data_json = <<JSON
{
  "license":     ${jsonencode(data.vault_generic_secret.automate_license.data["license"])},
  "private-key": ${jsonencode(tls_private_key.private_key.private_key_pem)}
}
JSON
}
