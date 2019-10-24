provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

data "vault_approle_auth_backend_role_id" "approle_auth_backend_role_id" {
  role_name = var.vault_role
}

resource "vault_approle_auth_backend_role_secret_id" "approle_auth_backend_role_secret_id" {
  role_name = var.vault_role
}
