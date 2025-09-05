variable "iso_file" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/debian-cd/13.0.0/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso"
}

variable "iso_storage_pool" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type    = string
  default = "sha512:069d47e9013cb1d651d30540fe8ef6765e5d60c8a14c8854dfb82e50bbb171255d2e02517024a392e46255dcdd18774f5cbd7e9f3a47aa1b489189475de62675"
}

variable "vm_name" {
  type = string
  default = "pckr-tmpl-debian-13"
}

variable "vmid" {
  type = string
  description = "Proxmox Template ID"
  default = "9999"
}

variable "cpu_type" {
  type    = string
  default = "kvm64"
}

variable "cores" {
  type    = string
  default = "2"
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "16G"
}

variable "storage_pool" {
  type    = string
  default = ""
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "network_vlan" {
  type    = string
  default = ""
}

variable "proxmox_api_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "proxmox_api_user" {
  type    = string
  default = "root@pam"
}

variable "proxmox_host" {
  type    = string
  default = ""
}

variable "proxmox_node" {
  type    = string
  default = ""
}

#No practical use of 'debian_root_password', since it is hard coded in pressed cfg.
variable "debian_root_password" {
  type      = string
  sensitive = true
  default   = "packer"
}

variable "preseed_url" {
  type    = string
  default = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg"
}
