terraform {
  backend "azurerm" {
    resource_group_name  = "liftoff-modern-application-delivery"
    storage_account_name = "liftoffmodernapplication"
    container_name       = "tfstate"
    key                  = "grafana-with-vault-integration.tfstate"
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
    X-Environment = var.tag_environment
    X-Contact     = var.tag_contact
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
    X-Environment = var.tag_environment
    X-Contact     = var.tag_contact
  }
}

resource "azurerm_dns_a_record" "dns_a_record" {
  name                = var.application_name
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  ttl                 = 300
  records             = [azurerm_public_ip.public_ip.ip_address]

  tags = {
    X-Environment = var.tag_environment
    X-Contact     = var.tag_contact
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
  vm_size               = "Standard_A2_v2"

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
    computer_name  = var.application_name
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
export HAB_LICENSE=accept-no-persist

sudo wget https://dl.eff.org/certbot-auto
sudo chmod a+x ./certbot-auto
sudo ./certbot-auto plugins --non-interactive

sudo ./certbot-auto certonly \
    --standalone \
    --agree-tos \
    --non-interactive \
    --staging \
    --domain ${local.fqdn} \
    --register-unsafely-without-email
EOF
    ]
  }

  provisioner "habitat" {
    accept_license = true
    peers          = [data.terraform_remote_state.bastion.outputs.fqdn]

    service {
      name      = format("%s/%s", var.habitat_origin, var.habitat_package)
      user_toml = templatefile(format("%s/templates/grafana-user.toml.tpl", path.module), {
        fqdn            = local.fqdn
        vault-address   = data.terraform_remote_state.vault.outputs.fqdn
        vault-role-id   = data.vault_approle_auth_backend_role_id.approle_auth_backend_role_id.role_id
        vault-secret-id = vault_approle_auth_backend_role_secret_id.approle_auth_backend_role_secret_id.secret_id
      })
    }
  }

  tags = {
    X-Environment = var.tag_environment
    X-Contact     = var.tag_contact
  }
}
