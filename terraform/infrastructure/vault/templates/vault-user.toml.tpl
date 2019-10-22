[listener]
port          = 443
tls_disable   = false
tls_cert_file = "/etc/letsencrypt/live/${fqdn}/fullchain.pem"
tls_key_file  = "/etc/letsencrypt/live/${fqdn}/privkey.pem"
