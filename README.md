Overview of the project : 
This project is about the creation of virtual environment using terrafrom script. There are two different ways to achive this 
1- By terrarom scripts
2- By using Azure Project.

Instructions to run the packer - 

Modify the server.json file as per your requirment.

Navigate to the server.json folder and execute below command. This will create the packer image.
Refer Packer-Image & Packer-Image1 from folder - ..Azure-cloud\Project-1\Azure-DevOps\Images
packer build -var 'subscription_id=****' -var 'tenant_id=***' -var 'client_id=***' -var 'client_secret=**_' server.json

Customisation - 
In future user want to change any value they can directly change into "terraform.auto.tfvars".

Deploy a Image using packer
How to use this project
Step 1 create VM image using packer
Create a resource group to hold packer image we have created resource group name as "packer-rg"

Udpate resource group in the server.json file


To build packer image i used below command

packer build -var 'subscription_id=xxxx' -var 'tenant_id=xxx' -var 'client_id=xxx' -var 'client_secret=xxx' server.json
Make sure that you have image created in the resource group

Build Environment using packer
In the solution folder , go to terraform.auto.tfvars.

Set the number of vm as vm_count in terraform.auto.tfvars

Set the packerimage resource group in azurepackageimagename 


Once you update , just run terraform plan -out solution.plan


Then you can terraform apply 

location              = "East US"
resourcegroup_vm      = "udacityresourcegroup"
virtual_network_name  = "odacitynw"
nw_ip_range           = ["10.0.0.0/16"]
azure_subnet_range    = ["10.0.2.0/24"]
azure_subnet_name     = "VM_subnet"
vm_nic_name           = "VM_NIC"
vm_name               = "odacityvm"
azurepackageimagename = "myPackerImage"
LBpublicip            = "PublicIPForLB"
loadbalancername      = "TestLoadBalancer"
resourcegroup_packer  = "packer-rg"
vm_username           = "azureuser"
HAsetname             = "HAforodacity"
diskname              = "odacityvmdisk"
HAforodacity          = "vmavailabilityset"
vm_count              = 1
policytagname         = "policytag"
policyassignment      = "tagpolicyassignment"
tag_name              = "udacity_env_tag_name"
vnet_address_spaces   = ["10.0.2.0/24"]
subnet_address_spaces = ["10.0.2.0/24"]
web_svc_port          = 80


Technical details


Overall design

Deploy azure policy which will denied if tag value is null to do that we have used policy.tf and policyassignment.tf




✓ Testing This is tested by executing in bash

# az policy assignment list
a diagram shows policy assignment
2. Packer template
2.1 Goal
The first thing we’re going to want to do is use Packer to create a server image, ensuring that the provided application is included in the template.

2.2 Solution


server.json file will have following things

image version as "18.04-LTS"
resource group for packer name as "packer-rg"

{
	"variables": {
		"client_id": "{{env `ARM_CLIENT_ID`}}",
		"client_secret": "{{env `ARM_CLIENT_SECRET`}}",
		"subscription_id": "{{env `ARM_SUBSCRIPTION_ID`}}",
        "tenant_id": "{{env `ARM_TENANT_ID`}}"
	},
	"builders": [{
		"type": "azure-arm",

        "client_id": "{{user `client_id`}}",
		"client_secret": "{{user `client_secret`}}",
		"subscription_id": "{{user `subscription_id`}}",
        "tenant_id": "{{user `tenant_id`}}",

    "managed_image_resource_group_name": "packer-rg",
    "managed_image_name": "myPackerImage",

    "os_type": "Linux",
    "image_publisher": "Canonical",
    "image_offer": "UbuntuServer",
    "image_sku": "18.04-LTS",

    "azure_tags": {
        "dept": "Engineering",
        "task": "Image deployment"
    },

    "location": "East US",
    "vm_size": "Standard_DS2_v2"
  }],
  "provisioners": [{
		"inline": [
			"echo 'Hello, World!' > index.html",
			"nohup busybox httpd -f -p 80 &"
		],
		"inline_shebang": "/bin/sh -x",
		"type": "shell"
   }]
}

3. Terraform Template
3.1 Goal
Terraform will create the infrastructure using IAC (Infrastructure as code) by using following commands
terraform init
terraform plan
terraform apply --auto-approve

3.2 Solution

Create azurerm_resource_group,azurerm_virtual_network, azurerm_subnet, azurerm_network_interface, azurerm_linux_virtual_machine, azurerm_managed_disk, azurerm_virtual_machine_data_disk_attachment  to do this we have block in vm.tf file

we have created azure load balancer for that we have loadbalancer.tf file

  

The below two creates the required vnet and subnets. The CIDR ranges are configurable through the variables

resource "azurerm_virtual_network" "net_web"
resource "azurerm_subnet" "internal"
✓ Create network security group - The nsg.tf file creates the NSG (Network Security Group)

# This  is the NSG
resource "azurerm_network_security_group" "allow_access"
# Rule 1 allow 80 port access
resource "azurerm_network_security_rule" "allow_access_from_intenet_80"
# Rule 2 allow all access within VNET
resource "azurerm_network_security_rule" "allow_access_from_vm_on_subnet"
✓ Create a public IP - This (networks.tf). This will be assigned to a NIC (below)


Data element azurerm_image

The VM resource

data "azurerm_image" "packerimage" {
  name                = "ubuntuBusyBox"
  resource_group_name = var.packerimage_rg
}

We have created load balancer using below scripts


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


create availability set using this terraform scripts

resource "azurerm_availability_set" "VMHA" {
  name                = var.HAforodacity
  location            = azurerm_resource_group.rg_vm.location
  resource_group_name = azurerm_resource_group.rg_vm.name

  tags = {
    environment = "odacityenv"
  }
}


below is output of the terraform plan

Terraform will perform the following actions:

PS D:\Temp\Payment\Azure-cloud\Project-1\Azure-DevOps> terraform plan

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_availability_set.VMHA will be created
  + resource "azurerm_availability_set" "VMHA" {
      + id                           = (known after apply)
      + location                     = "eastus"
      + managed                      = true
      + name                         = "vmavailabilityset"
      + platform_fault_domain_count  = 3
      + platform_update_domain_count = 5
      + resource_group_name          = "udacityresourcegroup"
      + tags                         = {
          + "environment" = "odacityenv"
        }
    }

  # azurerm_lb.lb will be created
  + resource "azurerm_lb" "lb" {
      + id                   = (known after apply)
      + location             = "eastus"
      + name                 = "TestLoadBalancer"
      + private_ip_address   = (known after apply)
      + private_ip_addresses = (known after apply)
      + resource_group_name  = "udacityresourcegroup"
      + sku                  = "Basic"

      + frontend_ip_configuration {
          + id                            = (known after apply)
          + inbound_nat_rules             = (known after apply)
          + load_balancer_rules           = (known after apply)
          + name                          = "PublicIPAddress"
          + outbound_rules                = (known after apply)
          + private_ip_address            = (known after apply)
          + private_ip_address_allocation = (known after apply)
          + private_ip_address_version    = "IPv4"
          + public_ip_address_id          = (known after apply)
          + public_ip_prefix_id           = (known after apply)
          + subnet_id                     = (known after apply)
        }
    }

  # azurerm_lb_backend_address_pool.backendpool will be created
  + resource "azurerm_lb_backend_address_pool" "backendpool" {
      + backend_ip_configurations = (known after apply)
      + id                        = (known after apply)
      + load_balancing_rules      = (known after apply)
      + loadbalancer_id           = (known after apply)
      + name                      = "BackEndAddressPool"
      + outbound_rules            = (known after apply)
      + resource_group_name       = (known after apply)
    }

  # azurerm_linux_virtual_machine.linux_vm[0] will be created
  + resource "azurerm_linux_virtual_machine" "linux_vm" {
      + admin_username                  = "azureuser"
      + allow_extension_operations      = true
      + availability_set_id             = (known after apply)
      + computer_name                   = (known after apply)
      + disable_password_authentication = true
      + extensions_time_budget          = "PT1H30M"
      + id                              = (known after apply)
      + location                        = "eastus"
      + max_bid_price                   = -1
      + name                            = "vmodacityvm0"
      + network_interface_ids           = (known after apply)
      + platform_fault_domain           = -1
      + priority                        = "Regular"
      + private_ip_address              = (known after apply)
      + private_ip_addresses            = (known after apply)
      + provision_vm_agent              = true
      + public_ip_address               = (known after apply)
      + public_ip_addresses             = (known after apply)
      + resource_group_name             = "udacityresourcegroup"
      + size                            = "Standard_F2"
      + source_image_id                 = "/subscriptions/b59daaf5-a6ef-4435-8b81-a93b295f0565/resourceGroups/TestPacker/providers/Microsoft.Compute/images/myPackerImage"
      + virtual_machine_id              = (known after apply)
      + zone                            = (known after apply)

      + admin_ssh_key {
          + public_key = (known after apply)
          + username   = "azureuser"
        }

      + os_disk {
          + caching                   = "ReadWrite"
          + disk_size_gb              = (known after apply)
          + name                      = (known after apply)
          + storage_account_type      = "Standard_LRS"
          + write_accelerator_enabled = false
        }
    }

  # azurerm_managed_disk.vmmanagedisk[0] will be created
  + resource "azurerm_managed_disk" "vmmanagedisk" {
      + create_option        = "Empty"
      + disk_iops_read_write = (known after apply)
      + disk_mbps_read_write = (known after apply)
      + disk_size_gb         = 1
      + id                   = (known after apply)
      + location             = "eastus"
      + name                 = "disk_odacityvmdisk_0"
      + resource_group_name  = "udacityresourcegroup"
      + source_uri           = (known after apply)
      + storage_account_type = "Standard_LRS"
    }

  # azurerm_network_interface.NIC[0] will be created
  + resource "azurerm_network_interface" "NIC" {
      + applied_dns_servers           = (known after apply)
      + dns_servers                   = (known after apply)
      + enable_accelerated_networking = false
      + enable_ip_forwarding          = false
      + id                            = (known after apply)
      + internal_dns_name_label       = (known after apply)
      + internal_domain_name_suffix   = (known after apply)
      + location                      = "eastus"
      + mac_address                   = (known after apply)
      + name                          = "nic_VM_NIC_0"
      + private_ip_address            = (known after apply)
      + private_ip_addresses          = (known after apply)
      + resource_group_name           = "udacityresourcegroup"
      + virtual_machine_id            = (known after apply)

      + ip_configuration {
          + name                          = "internal"
          + primary                       = (known after apply)
          + private_ip_address            = (known after apply)
          + private_ip_address_allocation = "dynamic"
          + private_ip_address_version    = "IPv4"
          + subnet_id                     = (known after apply)
        }
    }

  # azurerm_network_interface_backend_address_pool_association.backendipaddress[0] will be created
  + resource "azurerm_network_interface_backend_address_pool_association" "backendipaddress" {
      + backend_address_pool_id = (known after apply)
      + id                      = (known after apply)
      + ip_configuration_name   = "internal"
      + network_interface_id    = (known after apply)
    }

  # azurerm_network_security_group.allow_access will be created
  + resource "azurerm_network_security_group" "allow_access" {
      + id                  = (known after apply)
      + location            = "eastus"
      + name                = "deploy-web-sg"
      + resource_group_name = "udacityresourcegroup"
      + security_rule       = (known after apply)
      + tags                = {
          + "environment" = "odacityenv"
        }
    }

  # azurerm_network_security_rule.allow_access_from_intenet_80 will be created
  + resource "azurerm_network_security_rule" "allow_access_from_intenet_80" {
      + access                      = "Allow"
      + destination_address_prefix  = "*"
      + destination_port_range      = "80"
      + direction                   = "Inbound"
      + id                          = (known after apply)
      + name                        = "HTTP_80"
      + network_security_group_name = "deploy-web-sg"
      + priority                    = 1001
      + protocol                    = "Tcp"
      + resource_group_name         = "udacityresourcegroup"
      + source_address_prefix       = "*"
      + source_port_range           = "*"
    }

  # azurerm_network_security_rule.allow_access_from_vm_on_subnet will be created
  + resource "azurerm_network_security_rule" "allow_access_from_vm_on_subnet" {
      + access                       = "Allow"
      + destination_address_prefixes = [
          + "10.0.2.0/24",
        ]
      + destination_port_range       = "*"
      + direction                    = "Inbound"
      + id                           = (known after apply)
      + name                         = "access_from_same_subnet"
      + network_security_group_name  = "deploy-web-sg"
      + priority                     = 1002
      + protocol                     = "Tcp"
      + resource_group_name          = "udacityresourcegroup"
      + source_address_prefixes      = [
          + "10.0.2.0/24",
        ]
      + source_port_range            = "*"
    }

  # azurerm_policy_assignment.plassignment will be created
  + resource "azurerm_policy_assignment" "plassignment" {
      + description          = "Policy Assignment created via an Acceptance Test"
      + display_name         = "My tag Policy Assignment"
      + enforcement_mode     = true
      + id                   = (known after apply)
      + metadata             = jsonencode(
            {
              + category = "General"
            }
        )
      + name                 = "tagpolicyassignment"
      + parameters           = jsonencode(
            {
              + tagName = {
                  + value = "udacity_env_tag_name"
                }
            }
        )
      + policy_definition_id = (known after apply)
      + scope                = "/subscriptions/b59daaf5-a6ef-4435-8b81-a93b295f0565"

      + identity {
          + principal_id = (known after apply)
          + tenant_id    = (known after apply)
          + type         = (known after apply)
        }
    }

  # azurerm_policy_definition.policyfortag will be created
  + resource "azurerm_policy_definition" "policyfortag" {
      + display_name          = "my-policy-definition"
      + id                    = (known after apply)
      + management_group_id   = (known after apply)
      + management_group_name = (known after apply)
      + metadata              = jsonencode(
            {
              + category = "Tags"
              + version  = "1.0.1"
            }
        )
      + mode                  = "All"
      + name                  = "policytag"
      + parameters            = jsonencode(
            {
              + tagName = {
                  + metadata = {
                      + description = "Name of the tag, such as 'environment'"
                      + displayName = "Tag Name"
                    }
                  + type     = "String"
                }
            }
        )
      + policy_rule           = jsonencode(
            {
              + if   = {
                  + not = {
                      + exists = "false"
                      + field  = "[concat('tags[', parameters('tagName'), ']')]"
                    }
                }
              + then = {
                  + effect = "deny"
                }
            }
        )
      + policy_type           = "Custom"
    }

  # azurerm_public_ip.publicip will be created
  + resource "azurerm_public_ip" "publicip" {
      + allocation_method       = "Static"
      + fqdn                    = (known after apply)
      + id                      = (known after apply)
      + idle_timeout_in_minutes = 4
      + ip_address              = (known after apply)
      + ip_version              = "IPv4"
      + location                = "eastus"
      + name                    = "PublicIPForLB"
      + resource_group_name     = "udacityresourcegroup"
      + sku                     = "Basic"
    }

  # azurerm_resource_group.rg_vm will be created
  + resource "azurerm_resource_group" "rg_vm" {
      + id       = (known after apply)
      + location = "eastus"
      + name     = "udacityresourcegroup"
    }

  # azurerm_subnet.subnet will be created
  + resource "azurerm_subnet" "subnet" {
      + address_prefix                                 = (known after apply)
      + address_prefixes                               = [
          + "10.0.2.0/24",
        ]
      + enforce_private_link_endpoint_network_policies = false
      + enforce_private_link_service_network_policies  = false
      + id                                             = (known after apply)
      + name                                           = "VM_subnet"
      + resource_group_name                            = "udacityresourcegroup"
      + virtual_network_name                           = "odacitynw"
    }

  # azurerm_virtual_machine_data_disk_attachment.diskattachment[0] will be created
  + resource "azurerm_virtual_machine_data_disk_attachment" "diskattachment" {
      + caching                   = "ReadWrite"
      + create_option             = "Attach"
      + id                        = (known after apply)
      + lun                       = 10
      + managed_disk_id           = (known after apply)
      + virtual_machine_id        = (known after apply)
      + write_accelerator_enabled = false
    }

  # azurerm_virtual_network.vn_vm will be created
  + resource "azurerm_virtual_network" "vn_vm" {
      + address_space         = [
          + "10.0.0.0/16",
        ]
      + guid                  = (known after apply)
      + id                    = (known after apply)
      + location              = "eastus"
      + name                  = "odacitynw"
      + resource_group_name   = "udacityresourcegroup"
      + subnet                = (known after apply)
      + vm_protection_enabled = false
    }

  # tls_private_key.bastian_ssh_key will be created
  + resource "tls_private_key" "bastian_ssh_key" {
      + algorithm                  = "RSA"
      + ecdsa_curve                = "P224"
      + private_key_pem            = (sensitive value)
      + public_key_fingerprint_md5 = (known after apply)
      + public_key_openssh         = (known after apply)
      + public_key_pem             = (known after apply)
      + rsa_bits                   = 4096
    }

Plan: 18 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.