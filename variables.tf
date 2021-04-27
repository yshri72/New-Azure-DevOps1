variable "location" {
  type        = string
  description = " location of the project"
}
variable "resourcegroup_packer" {
  type        = string
  description = "resource group name_packer"
}
variable "resourcegroup_vm" {
  type        = string
  description = "resource group for vm"
}
variable "virtual_network_name" {
  type        = string
  description = "virtual nw name for vm"
}

variable "nw_ip_range" {
  type        = list(string)
  description = "nw_ip_range for VM"
}
variable "azure_subnet_range" {
  type        = list(string)
  description = "azure_subnet_range"
}
variable "azure_subnet_name" {
  type        = string
  description = "azure_subnet_name"
}
variable "vm_nic_name" {
  type        = string
  description = "vm_nic_name"
}

variable "vm_name" {
  type        = string
  description = "vm_name"
}



variable "azurepackageimagename" {
  type        = string
  description = "packer image name for VM"
}

variable "LBpublicip" {
  type        = string
  description = "public ip for lb"
}

variable "loadbalancername" {
  type        = string
  description = "load balancer name"
}
variable "vm_username" {
  type        = string
  description = "VM username"
}
variable "HAsetname" {
  type        = string
  description = "HAsetname"
}
variable "diskname" {
  type        = string
  description = "diskname"
}
variable "HAforodacity" {
  type        = string
  description = "diskname"
}
variable "vm_count" {
  type        = number
  description = "number of VM"
}
variable "policytagname" {
  type        = string
  description = "diskname"
}
variable "policyassignment" {
  type        = string
  description = "diskname"
}
variable "tag_name" {
  type        = string
  description = "polic tag name"
}

variable "web_svc_port" {
  type        = number
  description = "destination port range"
}

variable "vnet_address_spaces" {
  type        = list(string)
  description = "azure_subnet_range"

}
variable "subnet_address_spaces" {
  type        = list(string)
  description = "azure_subnet_range"

}









