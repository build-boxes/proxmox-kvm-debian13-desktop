variable "iso_file" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/debian-cd/13.3.0/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso"
}

variable "iso_storage_pool" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type    = string
  default = "sha512:1ada40e4c938528dd8e6b9c88c19b978a0f8e2a6757b9cf634987012d37ec98503ebf3e05acbae9be4c0ec00b52e8852106de1bda93a2399d125facea45400f8"
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

variable "disk_ssd_enabled" {
  type        = bool
  description = "Enable SSD flag for the disk"
  default     = true
  validation {
    condition     = var.disk_ssd_enabled == true || var.disk_ssd_enabled == false
    error_message = "Disk_ssd_enabled must be a boolean value (true or false)."
  }
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

variable "vm_image_tags" {
  type        = list(string)
  description = "Tags for the Packer template"
  default     = ["template", "debian", "debian13", "trixie", "desktop", "gnome", "docker"]
}

variable "superuser_name" {
  type        = string
  description = "Superuser name for cloud-init configuration"
  default     = ""
}

variable "superuser_gecos" {
  type        = string
  description = "Superuser GECOS/full name for cloud-init configuration"
  default     = ""
}

variable "superuser_password" {
  type        = string
  description = "Superuser password hash for cloud-init configuration"
  sensitive   = true
  default     = ""
}

variable "superuser_ssh_pub_key" {
  type        = string
  description = "Superuser SSH public key for cloud-init configuration"
  default     = ""
}

variable "common_name" {
  type        = string
  description = "Common Name for xRDP SSL certificate"
  default     = "debian.ca"
}
