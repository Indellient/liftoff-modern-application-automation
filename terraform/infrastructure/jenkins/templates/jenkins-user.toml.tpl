[admin]
username = "admin"
password = "${admin-password}"

[jenkins.https]
enabled            = true
key-store          = "/etc/letsencrypt/live/${fqdn}/cert.jks"
key-store-password = "${key-store-password}"

[[credentials]]
id          = "habitat-depot-token"
token       = "${hab-auth-token}"
description = "Habitat Builder Authentication Token"

[[credentials]]
id          = "arm-client-id"
token       = "${arm-client-id}"
description = "Azure Client ID"

[[credentials]]
id          = "arm-client-secret"
token       = "${arm-client-secret}"
description = "Azure Client Secret"

[[credentials]]
id          = "arm-tenant-id"
token       = "${arm-tenant-id}"
description = "Azure Tenant ID"

[[credentials]]
id          = "arm-subscription-id"
token       = "${arm-subscription-id}"
description = "Azure Subscription ID"

[[credentials]]
id          = "vault-token"
token       = "${vault-token}"
description = "Vault Token"
