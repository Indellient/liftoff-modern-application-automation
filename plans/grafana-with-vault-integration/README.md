# Chef Habitat package: Grafana

## Description

This Chef Habitat package installs Grafana for linux using standalone binaries. By default, it does not include any datasources and listens on port 8000, and can be configured with a certificate/key.

Note this is based off `core/grafana` (https://github.com/habitat-sh/core-plans/blob/master/grafana), though slightly slimmed down and updated.
This particular variant comes with Vault integration, and in the presence of the correct values (see `./default.toml`) will read the administrator password from vault instead of the service configuration.

## Usage

The package can be loaded using `hab svc load` and will come up in a blank state, ready for DataSources and Dashboards to be added by the user.

## Vault Usage
### Vault Setup
To setup Vault integration, we must first setup [AppRole Authentication](https://www.vaultproject.io/docs/auth/approle.html) on Vault:

- Provision a secret in Vault, noting the path and field name (`secret/grafana` & `password` here, respectively):
  ```bash
  $ vault kv put secret/grafana password=<value>
  Success! Data written to: secret/grafana
  ```
- Create a Policy for Grafana, allowing it to log in using AppRole Authentication and read the value at the path of the secret we created prior.
  ```bash
  $ vault policy write grafana - <<EOF
  path "auth/approle/login" {
    capabilities = [ "create" ]
  }

  path "secret/grafana" {
    capabilities = [ "read" ]
  }
  EOF
  Success! Uploaded policy: grafana
  ```
- Enable AppRole Authentication:
  ```bash
  $ vault auth enable approle
  Success! Enabled approle auth method at: approle/
  ```
- Create Role for Grafana:
  ```bash
  $ vault write auth/approle/role/grafana \
    secret_id_ttl=25h \
    token_num_uses=10 \
    token_ttl=15m \
    token_max_ttl=1h \
    policies=grafana \
    secret_id_num_uses=10
  Success! Data written to: auth/approle/role/grafana
  ```
We can now make use of Vault from within Grafana. This can be done by providing a Role ID and Secret ID to the service, think of this as a username/password pair that is used to authenticate with Vault returning a token. This token, working similar to a Session ID or Cookie can now be used to retrieve secrets, though only where the policy allows. In our example above, we attached the `grafana` policy to the `grafana` role we created.

### Application Vault Configuration
We can retrieve a Secret ID and Role ID like so:
```bash
$ vault read auth/approle/role/grafana/role-id
Key        Value
---        -----
role_id    2f87c28f-b533-bb6b-9d9e-685c68334216
```
As mentioned before, this Role ID acts like a username. We can then create a password that can be used with this Role ID as so:
```bash
$ vault write -f auth/approle/role/grafana/secret-id
Key                   Value
---                   -----
secret_id             68e51746-c78d-6abc-28e6-043f26b744a1
secret_id_accessor    1b338b4c-d430-b468-fdcd-e6c4a662fde2
```

Note that at this point we can simply provide these as configuration values to the service, which will handle the login using the Secret ID and Role ID:
```bash
$ cat config.toml
[vault]
address   = "<vault-address>"
role-id   = "2f87c28f-b533-bb6b-9d9e-685c68334216"
secret-id = "68e51746-c78d-6abc-28e6-043f26b744a1"

[vault.secret]
path      = "secret/grafana"
field     = "password"

$ hab config apply grafana.default <version-number> config.toml
» Setting new configuration version <version-number> for grafana.default
Ω Creating service configuration
↑ Applying via peer 127.0.0.1:9632
★ Applied configuration
``` 

You can see how the application authenticates from Vault and retrieves the secret in the run hook (`./hooks/run`), seen here:
```bash
export VAULT_ADDR="{{cfg.vault.address}}"

...

CREDENTIALS=$(vault write auth/approle/login --format=json \
  role_id="{{cfg.vault.role-id}}" \
  secret_id="{{cfg.vault.secret-id}}")

# VAULT_ADDR & VAULT_TOKEN have been exported, we can now read from vault
export VAULT_TOKEN=$(echo ${CREDENTIALS} | jq -r .auth.client_token)

vault read -field={{cfg.vault.secret.field}} {{cfg.vault.secret.path}}
```
Note that you can see the rendered hook with configuration values interpolated in `/hab/svc/<service-name>/hooks` when the service is loaded.

#### Manual Test
You can test this vault behaviour yourself to understand how this is working (note, pass `--format "json"` for more machine-parsable syntax):
```bash
$ vault write auth/approle/login role_id="2f87c28f-b533-bb6b-9d9e-685c68334216" secret_id="68e51746-c78d-6abc-28e6-043f26b744a1"
Key                     Value
---                     -----
token                   s.mzGgVXF36r3CwvSREGLTzBV8
token_accessor          YATwz4QW6qdygsmMpCSvLiyd
token_duration          15m
token_renewable         true
token_policies          ["default" "grafana"]
identity_policies       []
policies                ["default" "grafana"]
token_meta_role_name    grafana
```
As we can see, this token is associated with the policies given by the authentication mechanism, in this case profile `grafana`. With this we can read the secret at `secret/grafana`:
```bash
$ VAULT_TOKEN=s.mzGgVXF36r3CwvSREGLTzBV8 vault kv get secret/grafana
====== Data ======
Key         Value
---         -----
password    <password>
```
