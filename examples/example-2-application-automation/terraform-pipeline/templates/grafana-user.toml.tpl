# The port + protocol that the Grafana UI listens on
http_port = 443
protocol = "https"

# SSL certificates, if protocol = "https"
cert_file = "/etc/letsencrypt/live/${fqdn}/fullchain.pem"
cert_key  = "/etc/letsencrypt/live/${fqdn}/privkey.pem"
