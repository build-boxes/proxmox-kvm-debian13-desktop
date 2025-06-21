variable "iso_file" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/debian-cd/12.11.0/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso"
}

variable "iso_storage_pool" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type    = string
  default = "sha512:0921d8b297c63ac458d8a06f87cd4c353f751eb5fe30fd0d839ca09c0833d1d9934b02ee14bbd0c0ec4f8917dde793957801ae1af3c8122cdf28dde8f3c3e0da"
}

variable "vm_name" {
  type = string
  default = "pckr-tmpl-debian-12"
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
