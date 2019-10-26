#!/bin/bash

password=${1}

_enable_secrets_engine(){
  local __ENGINE=${1}
  local __PATH=${2}

  local engines=$(vault secrets list --format "json" | jq -r '.[].type')
  if [[ ! "${engines[@]}" =~ "${__ENGINE}" ]]; then
    echo "Enabling secret engine ${__ENGINE}"
    vault secrets enable --path ${__PATH} ${__ENGINE}
  else
    echo "Secret engine ${__ENGINE} already enabled; skipping..."
  fi
}

_enable_auth_method() {
  local __METHOD=${1}

  local methods=$(vault auth list --format json | jq -r '.[].type')
  if [[ ! "${methods[@]}" =~ "${__METHOD}" ]]; then
    echo "Enabling Authentication Method ${__METHOD}"
    vault auth enable ${__METHOD}
  else
    echo "Authentication Method ${__METHOD} already enabled; skipping..."
  fi
}

if [ -z "${VAULT_TOKEN}" ] || [ -z "${VAULT_ADDR}" ]; then
  echo "Incorrect Vault Configuration!"
  echo "VAULT_ADDR and VAULT_TOKEN are required"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "jq not installed! jq is required for this script"
fi

_enable_secrets_engine "kv" "secret/"
_enable_auth_method "approle"

# Create Secret
vault kv put secret/grafana password=${password}

# Create Grafana Policy
vault policy write grafana - <<EOF
path "secret/grafana" {
  capabilities = [ "read" ]
}
EOF

# Create Role
vault write auth/approle/role/grafana policies=grafana

# Create Jenkins Role
vault policy write jenkins - <<EOF
path "auth/approle/role/grafana/role-id" {
  capabilities = [ "read" ]
}

path "auth/approle/role/grafana/secret-id" {
  capabilities = [ "create", "update" ]
}

path "auth/approle/role/grafana/secret-id-accessor/*" {
  capabilities = [ "create", "read", "update", "list" ]
}

path "auth/token/create" {
  capabilities = [ "read", "create", "update", "delete" ]
}
EOF

response=$(vault token create -policy jenkins -format "json")
echo "Created Jenkins token '$(echo $response | jq -r .auth.client_token)'"
