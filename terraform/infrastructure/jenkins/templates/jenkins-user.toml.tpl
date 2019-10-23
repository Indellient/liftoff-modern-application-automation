[admin]
username = "admin"
password = "${admin-password}"

[jenkins.https]
enabled            = true
key-store          = "/etc/letsencrypt/live/${fqdn}/cert.jks"
key-store-password = "${key-store-password}"
