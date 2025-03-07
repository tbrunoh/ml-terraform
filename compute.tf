
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vmss_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vmss_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP for the load balancer
resource "azurerm_public_ip" "pip" {
  name                = "${var.vmss_name}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create load balancer
resource "azurerm_lb" "lb" {
  name                = "${var.vmss_name}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

# Create backend address pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

# Create a load balancer rule
resource "azurerm_lb_rule" "ssh_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSHRule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.ssh_probe.id
}

# Create a load balancer probe
resource "azurerm_lb_probe" "ssh_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "ssh-running-probe"
  port            = 22
}

# Define VM sizes based on GPU count
locals {
  
  # Default setup script for ML development if custom_data_script is not provided
  default_custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install dependencies
    apt-get update
    apt-get install -y nvidia-driver-535 nvidia-cuda-toolkit
    
    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
    
    # Add user to docker group
    usermod -aG docker ${var.admin_username}
    
    # Install NVIDIA Docker
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
    apt-get update
    apt-get install -y nvidia-docker2
    
    # Install Python ML packages
    apt-get install -y python3-pip
    pip3 install torch torchvision tensorflow jupyter
    
    # Create a data directory
    mkdir -p /data
    chmod 777 /data
    
    # Restart Docker to apply nvidia-docker settings
    systemctl restart docker
  EOF
  )
}

# Create VMSS
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                 = var.vmss_name
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = var.vm_size
  instances            = var.instance_count
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  disable_password_authentication = false
  
  custom_data = var.custom_data_script != null ? var.custom_data_script : local.default_custom_data
  
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }
  
  data_disk {
    lun                  = 0
    caching              = "ReadWrite"
    create_option        = "Empty"
    disk_size_gb         = var.data_disk_size_gb
    storage_account_type = "Premium_LRS"
  }
  
  network_interface {
    name    = "nic"
    primary = true
    
    ip_configuration {
      name                                   = "internal"
      primary                               = true
      subnet_id                             = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [instances]
  }
}

# Add auto-scaling
resource "azurerm_monitor_autoscale_setting" "auto_scale" {
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "DefaultProfile"

    capacity {
      default = var.instance_count
      minimum = var.instance_count
      maximum = 2  # Max 2 instances for cost control
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }


    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 20
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.tags
}

# Outputs
output "vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "public_ip_address" {
  description = "Public IP address of the load balancer"
  value       = azurerm_public_ip.pip.ip_address
}

output "selected_vm_size" {
  description = "The VM size selected based on GPU count"
  value       = var.vm_size
}