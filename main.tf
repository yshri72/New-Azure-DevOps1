resource "azurerm_availability_set" "VMHA" {
  name                = var.HAforodacity
  location            = azurerm_resource_group.rg_vm.location
  resource_group_name = azurerm_resource_group.rg_vm.name

  tags = {
    environment = "odacityenv"
  }
}
resource "azurerm_public_ip" "publicip" {
  name                = var.LBpublicip
  location            = azurerm_resource_group.rg_vm.location
  resource_group_name = azurerm_resource_group.rg_vm.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  name                = var.loadbalancername
  location            = azurerm_resource_group.rg_vm.location
  resource_group_name = azurerm_resource_group.rg_vm.name


  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }

}
resource "azurerm_lb_backend_address_pool" "backendpool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "backendipaddress" {
  count                   = var.vm_count
  network_interface_id    = element(azurerm_network_interface.NIC, count.index).id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendpool.id
}

resource "azurerm_network_security_group" "allow_access" {
  name                = "deploy-web-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_vm.name

  tags = {
    environment = "odacityenv"
  }
}

resource "azurerm_network_security_rule" "allow_access_from_intenet_80" {
  name                        = "HTTP_80"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = var.web_svc_port
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_vm.name
  network_security_group_name = azurerm_network_security_group.allow_access.name
}

resource "azurerm_network_security_rule" "allow_access_from_vm_on_subnet" {
  name                         = "access_from_same_subnet"
  priority                     = 1002
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = var.vnet_address_spaces
  destination_address_prefixes = var.subnet_address_spaces
  resource_group_name          = azurerm_resource_group.rg_vm.name
  network_security_group_name  = azurerm_network_security_group.allow_access.name
}
resource "azurerm_policy_definition" "policyfortag" {
  name         = var.policytagname
  policy_type  = "Custom"
  mode         = "All"
  display_name = "my-policy-definition"

  metadata = <<METADATA
    {
     "version": "1.0.1",
     "category": "Tags"
    }
METADATA

  policy_rule = <<POLICY_RULE
    {
    "if": {
      "not": {
        "field": "[concat('tags[', parameters('tagName'), ']')]",
        "exists": "false"
      }
    },
    "then": {
      "effect": "deny"
    }
  }
POLICY_RULE

  parameters = <<PARAMETERS
    {
   "tagName": {
        "type": "String",
        "metadata": {
            "displayName": "Tag Name",
            "description": "Name of the tag, such as 'environment'"
        }
    }
  }
PARAMETERS
}
data "azurerm_subscription" "current" {

}
resource "azurerm_policy_assignment" "plassignment" {
  name                 = var.policyassignment
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.policyfortag.id
  description          = "Policy Assignment created via an Acceptance Test"
  display_name         = "My tag Policy Assignment"

  metadata = <<METADATA
  {
    "category": "General"
  }
METADATA

  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "${var.tag_name}"
             }
}
PARAMETERS

  depends_on = [azurerm_policy_definition.policyfortag]
}
# Create SSH key
resource "tls_private_key" "bastian_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "rg_vm" {
  name     = var.resourcegroup_vm
  location = var.location


}

resource "azurerm_virtual_network" "vn_vm" {
  name                = var.virtual_network_name
  address_space       = var.nw_ip_range
  location            = azurerm_resource_group.rg_vm.location
  resource_group_name = azurerm_resource_group.rg_vm.name

}

resource "azurerm_subnet" "subnet" {
  name                 = var.azure_subnet_name
  resource_group_name  = azurerm_resource_group.rg_vm.name
  virtual_network_name = azurerm_virtual_network.vn_vm.name
  address_prefixes     = var.azure_subnet_range

}


resource "azurerm_network_interface" "NIC" {
  count               = var.vm_count
  name                = "nic_${var.vm_nic_name}_${count.index}"
  location            = azurerm_resource_group.rg_vm.location
  resource_group_name = azurerm_resource_group.rg_vm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

}

data "azurerm_image" "packerimage" {
  name                = var.azurepackageimagename
  resource_group_name = var.resourcegroup_packer
  #location            = azurerm_resource_group.rg_vm.location
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  count               = var.vm_count
  name                = "vm${var.vm_name}${count.index}"
  resource_group_name = azurerm_resource_group.rg_vm.name
  location            = azurerm_resource_group.rg_vm.location
  size                = "Standard_F2"
  admin_username      = var.vm_username
  source_image_id     = data.azurerm_image.packerimage.id
  availability_set_id = azurerm_availability_set.VMHA.id
  network_interface_ids = [

    element(azurerm_network_interface.NIC, count.index).id

  ]

  admin_ssh_key {
    username   = var.vm_username
    public_key = tls_private_key.bastian_ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  # depends_on = [azurerm_image.packerimage, ]
}
resource "azurerm_managed_disk" "vmmanagedisk" {

  count = var.vm_count
  name  = "disk_${var.diskname}_${count.index}"


  location             = azurerm_resource_group.rg_vm.location
  resource_group_name  = azurerm_resource_group.rg_vm.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
}


resource "azurerm_virtual_machine_data_disk_attachment" "diskattachment" {


  count = var.vm_count

  managed_disk_id    = element(azurerm_managed_disk.vmmanagedisk, count.index).id
  virtual_machine_id = element(azurerm_linux_virtual_machine.linux_vm, count.index).id
  lun                = "10"
  caching            = "ReadWrite"
}


