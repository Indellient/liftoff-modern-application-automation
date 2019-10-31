////////////////////////////
///// Azure

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group where resources will exist."
  default     = "liftoff-modern-application-delivery"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the Azure Storage Account to use."
  default     = "liftoffmodernapplication"
}

variable "image_name" {
  type        = string
  description = "The name of the Azure Machine Image to use."
  default     = "centos-habitat-base-applications"
}

////////////////////////////
///// Centos

variable "admin_username" {
  type        = string
  description = "The name of the admin username on each VM."
  default     = "centos"
}

////////////////////////////
///// Habitat

variable "consul_habitat_package" {
  type        = string
  description = "The Habitat package to load"
  default     = "consul"
}

variable "consul_habitat_origin" {
  type        = string
  description = "The name of the origin from which to load the package given in consul_habitat_package"
  default     = "liftoff-modern-application-delivery"
}

variable "vault_habitat_package" {
  type        = string
  description = "The Habitat package to load"
  default     = "vault"
}

variable "vault_habitat_origin" {
  type        = string
  description = "The name of the origin from which to load the package given in vault_habitat_package"
  default     = "liftoff-modern-application-delivery"
}

////////////////////////////
///// Tags

variable "application_name" {
  type        = string
  description = "Name of application used in naming resources."
  default     = "vault"
}

variable "tag_project" {
  type        = string
  description = "Project Tag"
  default     = "sales-event-demo"
}

variable "tag_contact" {
  type        = string
  description = "Contact information tag"
  default     = "Siraj Rauff <siraj.rauff@indellient.com>"
}
