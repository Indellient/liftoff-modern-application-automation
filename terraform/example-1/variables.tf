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
  description = "The name of the Azure DNS Zone to use."
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
///// Tags

variable "application_name" {
  type        = string
  description = "Name of application used in naming resources."
  default     = "server-with-base-applications"
}

variable "tag_environment" {
  type        = string
  description = "Environment Tag"
  default     = "sales-event-demo"
}

variable "tag_contact" {
  type        = string
  description = "Contact information tag"
  default     = "Siraj Rauff <siraj.rauff@indellient.com>"
}
