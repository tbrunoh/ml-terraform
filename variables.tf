
# Variables for configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "ml-dev-gpu-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "centralus"
}

variable "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
  default     = "ml-dev-vmss"
}

variable "instance_count" {
  description = "Number of VM instances in the scale set"
  type        = number
  default     = 1
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
  default = "Psenjen9$"
}

variable "vm_size" {
  description = "Size of the VM (GPU-enabled)"
  type        = string
  default     = "Standard_NC24ads_A100_v4" # 1 NVIDIA Tesla V100 GPU
}

variable "gpu_count" {
  description = "Number of GPUs (choose VM size accordingly)"
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 2, 4, 8], var.gpu_count)
    error_message = "GPU count must be 1, 2, 4, or 8, and VM size must support the selected count."
  }
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "microsoft-dsvm"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "ubuntu-2004"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "2004-gen2"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

variable "os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 256
}

variable "data_disk_size_gb" {
  description = "Size of additional data disk in GB"
  type        = number
  default     = 256
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Purpose     = "ML-Training"
  }
}

variable "custom_data_script" {
  description = "Base64-encoded custom data script"
  type        = string
  default     = null
}
