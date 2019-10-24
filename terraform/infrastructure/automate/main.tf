terraform {
  backend "azurerm" {
    resource_group_name  = "liftoff-modern-application-delivery"
    storage_account_name = "liftoffmodernapplication"
    container_name       = "tfstate"
    key                  = "automate.tfstate"
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "azurerm_public_ip" "public_ip" {
  name                = format("%s-public-ip", var.application_name)
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "azurerm_network_interface" "network_interface" {
  name                = format("%s-network-interface", var.application_name)
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = format("%s-public-ip-configuration", var.application_name)
    subnet_id                     = data.terraform_remote_state.networking.outputs.public_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "azurerm_dns_a_record" "dns_a_record" {
  name                = var.application_name
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  ttl                 = 300
  records             = [azurerm_public_ip.public_ip.ip_address]

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

locals {
  fqdn = format("%s.%s", azurerm_dns_a_record.dns_a_record.name, azurerm_dns_a_record.dns_a_record.zone_name)
}

resource "azurerm_virtual_machine" "virtual_machine" {
  connection {
    host        = azurerm_public_ip.public_ip.ip_address
    type        = "ssh"
    user        = var.admin_username
    private_key = trimspace(tls_private_key.private_key.private_key_pem)
  }

  name                  = var.application_name
  resource_group_name   = data.azurerm_resource_group.resource_group.name
  location              = data.azurerm_resource_group.resource_group.location
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  vm_size               = "Standard_B4ms"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  boot_diagnostics {
    enabled     = false
    storage_uri = ""
  }

  storage_image_reference {
    id = data.azurerm_image.image.id
  }

  storage_os_disk {
    name              = format("%s-os-disk", var.application_name)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = format("%s", var.application_name)
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = tls_private_key.private_key.public_key_openssh
    }
  }

  provisioner "remote-exec" {
    inline = [<<EOF
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.dirty_expire_centisecs=20000

tempDir=$(mktemp -d)
echo "Using $${tempDir}"
pushd $${tempDir}

sudo wget https://dl.eff.org/certbot-auto
sudo chmod a+x ./certbot-auto
sudo ./certbot-auto plugins --non-interactive

# Deploy automate
sudo ./certbot-auto certonly \
    --standalone \
    --agree-tos \
    --non-interactive \
    --domain ${local.fqdn} \
    -m siraj.rauff@indellient.com

privateKey=$(sudo cat /etc/letsencrypt/live/${local.fqdn}/privkey.pem)
fullchain=$(sudo cat /etc/letsencrypt/live/${local.fqdn}/fullchain.pem)

cat > config.toml <<TOML
[global.v1]
fqdn = "${local.fqdn}"

[[global.v1.frontend_tls]]
cert = """$${fullchain}"""
key = """$${privateKey}"""

[license_control.v1.svc]
license = "${var.automate_license}"
TOML

curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate
sudo chmod +x ./chef-automate
sudo ./chef-automate deploy config.toml --accept-terms-and-mlsa
sudo mv automate-credentials.toml /root/automate-credentials.toml

popd
EOF
    ]
  }

  tags = {
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}
