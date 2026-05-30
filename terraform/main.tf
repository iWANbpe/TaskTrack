terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "virtualbox" {}

resource "virtualbox_vm" "worker" {
  name   = "lab4-worker"
  image  = var.vm_image
  cpus   = 1
  memory = "1024 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = var.hostonly_interface
  }

  user_data = templatefile("${path.module}/cloud-init/worker.yaml", {
    student_ssh_public_key = var.student_ssh_public_key
  })
}

resource "virtualbox_vm" "db" {
  name   = "lab4-db"
  image  = var.vm_image
  cpus   = 1
  memory = "1024 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = var.hostonly_interface
  }

  user_data = templatefile("${path.module}/cloud-init/db.yaml", {
    student_ssh_public_key = var.student_ssh_public_key
  })
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    worker_ip = virtualbox_vm.worker.network_adapter[0].ipv4_address
    db_ip     = virtualbox_vm.db.network_adapter[0].ipv4_address
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

output "worker_ip" {
  description = "IP address of the worker VM"
  value       = virtualbox_vm.worker.network_adapter[0].ipv4_address
}

output "db_ip" {
  description = "IP address of the DB VM"
  value       = virtualbox_vm.db.network_adapter[0].ipv4_address
}
