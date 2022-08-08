# Connection settings
variable "vcenter_address" {
  type    = string
  default = "vcsa.aljb.dev"
}

variable "vcsa_password" {
  description = "Password for vCenter"
}

locals {
  vcenter_user     = "administrator@vcsa.aljb.dev"
  vcenter_password = var.vcsa_password
}

# Location settings
variable "vcenter_dc" {
  type    = string
  default = "NN14"
}

variable "vcenter_datastore" {
  type    = string
  default = "datastore1"
}

variable "vcenter_network" {
  type    = string
  default = "Infra"
}

variable "vm_name" {
  type    = string
  default = "ubuntu2204-vco-template"
}

source "vsphere-iso" "vm" {
  vcenter_server      = var.vcenter_address
  username            = local.vcenter_user
  password            = local.vcenter_password
  insecure_connection = true

  datacenter = var.vcenter_dc
  host = "10.1.0.2"
  datastore  = var.vcenter_datastore
  vm_name    = var.vm_name

  CPUs                 = 2
  RAM                  = 4096
  disk_controller_type = ["scsi"]
  guest_os_type        = "ubuntu64Guest"
  network_adapters {
    network      = var.vcenter_network
    network_card = "vmxnet3"
  }
  iso_url             = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
  iso_checksum        = "file:https://releases.ubuntu.com/22.04/SHA256SUMS"
  convert_to_template = true
  storage {
    disk_size             = 40960
    disk_thin_provisioned = true
  }

  cd_files = [
    "./cloud-init/meta-data",
    "./cloud-init/user-data"
  ]
  cd_label = "cidata"

  boot_command = [
    "<esc><esc><esc><esc>e<wait>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "linux /casper/vmlinuz --- autoinstall<enter><wait>",
    "initrd /casper/initrd ",
    "boot<enter>",
    "<enter><f10><wait>"
  ]
  boot_wait = "5s"

  ip_wait_timeout  = "3600s"
  shutdown_command = "echo 'system' | sudo -S shutdown -P now"
  ssh_password     = "changeme"
  ssh_port         = 22
  ssh_timeout      = "10m"
  ssh_handshake_attempts = 100
  ssh_username     = "system"
}

build {
  sources = ["source.vsphere-iso.vm"]

  provisioner "shell" {
    execute_command = "echo 'changeme' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "./scripts/setup_ubuntu2204.sh"
  }
}
