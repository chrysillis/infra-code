variable "resource_group_name" {
  default = "terraform-test"
  description = "Resource group name"
}
variable "resource_region" {
  default = "westus2"
  description = "Region of the resource"
}
variable "admin_username" {
  default = "chrysi"
  description = "Username for admin user"
}
variable "vm_size" {
  default = "Standard_B2ms"
  description = "Size of the VM"
}
variable "os_image" {
  default = "2022-datacenter-azure-edition"
  description = "Version of Windows OS to use"
}
variable "name" {
  default = "CC"
  description = "Prefix for VM name"
}