#!/bin/bash

password=${1}
field=${2:-"password"}
path=${3:-"secret/grafana"}
policyname=${3:-"grafana"}
rolename=${3:-"grafana"}

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
vault kv put ${path} ${field}=${password}

# Put Policy
vault policy write ${policyname} - <<EOF
path "${path}" {
  capabilities = [ "read" ]
}
EOF

# Create Role
vault write auth/approle/role/${rolename} policies=${policyname}
