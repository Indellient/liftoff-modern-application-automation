terraform {
  backend "azurerm" {
    resource_group_name  = "liftoff-modern-application-delivery"
    storage_account_name = "liftoffmodernapplication"
    container_name       = "tfstate"
    key                  = "vault.tfstate"
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "azurerm_public_ip" "public_ip" {
  name                = "vault-public-ip"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  allocation_method   = "Static"

  tags = {
    X-Environment = var.tag_environment
    X-Contact     = var.tag_contact
  }
}

resource "azurerm_network_interface" "network_interface" {
  name                = "vault-network-interface"
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "vault-public-ip-configuration"
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
  name                = "vault"
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

  name                  = "vault"
  resource_group_name   = data.azurerm_resource_group.resource_group.name
  location              = data.azurerm_resource_group.resource_group.location
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  vm_size               = "Standard_B2s"

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
    name              = "vault-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "vault"
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

tempDir=$(mktemp -d)
echo "Using $${tempDir}"
pushd $${tempDir}

sudo wget https://dl.eff.org/certbot-auto
sudo chmod a+x ./certbot-auto
sudo ./certbot-auto plugins --non-interactive

# Deploy vault
sudo ./certbot-auto certonly \
    --standalone \
    --agree-tos \
    --non-interactive \
    --domain ${local.fqdn} \
    -m siraj.rauff@indellient.com
popd
EOF
    ]
  }

  provisioner "habitat" {
    accept_license = true
    use_sudo       = true

    service {
      name = "indellient/consul"
    }
  }

  tags = {
    X-Environment = var.tag_environment
    X-Contact     = var.tag_contact
  }
}

resource "null_resource" "null_resource" {
  connection {
    host        = azurerm_public_ip.public_ip.ip_address
    type        = "ssh"
    user        = var.admin_username
    private_key = trimspace(tls_private_key.private_key.private_key_pem)
  }

  provisioner "remote-exec" {
    inline = [
      "until $(hab pkg path core/consul)/bin/consul members &> /dev/null; do echo 'Waiting for Consul...'; sleep 1; done"
    ]
  }

  provisioner "habitat" {
    accept_license = true
    use_sudo       = true

    service {
      name      = "indellient/vault"
      user_toml = templatefile(format("%s/templates/vault-user.toml.tpl", path.module), { fqdn = local.fqdn })

      bind {
        alias   = "backend"
        service = "consul"
        group   = "default"
      }
    }
  }

  depends_on = [ "azurerm_virtual_machine.virtual_machine" ]
}