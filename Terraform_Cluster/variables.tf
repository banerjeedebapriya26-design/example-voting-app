variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
  default     = "centralIndia"
}

variable "prefix" {
  type        = string
  description = "Prefix of the resources to be created"
  default     = "docker-demoapp"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

variable "address_space_subnet" {
  type        = list(string)
  description = "Address space for the subnet"
  default     = ["10.0.2.0/24"]
}

variable "env" {
  type        = string
  description = "environment for the deployment"
  default     = "development"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM for the AKS node pool"
  default     = "Standard_D2s_v3"
}