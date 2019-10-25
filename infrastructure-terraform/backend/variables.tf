variable "resource_group_location" {
  type        = string
  description = "The Location for the Azure Resource Group where resources will exist."
  default     = "eastus"
}

////////////////////////////
///// Tags

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
