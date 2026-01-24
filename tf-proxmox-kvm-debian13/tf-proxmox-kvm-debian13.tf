# Adapted from: https://github.com/build-boxes/terraform-proxmox-windows-example/blob/main/main.tf
#
#
# see https://github.com/hashicorp/terraform
terraform {
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.6"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.75.0"
    }
    time = {
          source = "hashicorp/time"
          version = "0.13.1"
    }
  }
}

provider "proxmox" {
    endpoint = var.PROXMOX_VE_ENDPOINT
    username = var.PROXMOX_VE_USERNAME
    password = var.PROXMOX_VE_PASSWORD
    insecure = var.PROXMOX_VE_INSECURE
  ssh {
    agent = true
    node {  
      name    = var.proxmox_node_name
      address = var.proxmox_node_address
    }
  }
}

variable "proxmox_node_name" {
  type    = string
  default = "pve"
}

variable "proxmox_node_address" {
  type = string
}

variable "PROXMOX_VE_ENDPOINT" {
    type = string
    default = "https://192.168.4.20:8006/api2/json"
}

variable "PROXMOX_VE_USERNAME" {
    type = string
    sensitive = true
    default = "admin@pve"
}

variable "PROXMOX_VE_PASSWORD" {
    type = string
    sensitive = true
    default = "PassW0rd123!!"
}

variable "PROXMOX_VE_INSECURE" {
    type = bool
    default = false
}


variable "prefix" {
  # This is used to rename the host to this name.description
  # also used as a prefix for text and log files names.
  type    = string
  default = "falcon02"
}

variable "pub_key_file" {
  type = string
  #default = "~/.ssh/id_rsa.pub"
}

variable "pvt_key_file" {
  type = string
  #default = "~/.ssh/id_rsa"
  sensitive = true
}

variable "superuser_username" {
  type    = string
  default = "terraform"
}

variable "superuser_old_password" {
  type      = string
  sensitive = true
  # NB the password will be reset by the cloudbase-init SetUserPasswordPlugin plugin.
  # NB this value must meet the Windows password policy requirements.
  #    see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
  # Password with @ symbol has issues in cloudbase-init scripts escape-sequencing in terraform ".tf" files
  default = "HeyH0Password"
}

variable "superuser_new_password" {
  type      = string
  sensitive = true
  # NB the password will be reset by the cloudbase-init SetUserPasswordPlugin plugin.
  # NB this value must meet the Windows password policy requirements.
  #    see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
  # Password with @ symbol has issues in cloudbase-init scripts escape-sequencing in terraform ".tf" files
  default = "HeyH0Password"
}

variable "root_new_password" {
  type      = string
  sensitive = true
  default = "HeyH0Password"
}

variable "proxmox_vm_template_tags" {
  type        = list(string)
  description = "Tags to filter Proxmox VM templates"
  default     = ["debian", "debian13", "desktop", "docker", "gnome", "template", "trixie"]
}

variable "proxmox_vm_tags" {
  type        = list(string)
  description = "Tags to assign to created Proxmox VMs"
  default     = ["debian13", "desktop", "example", "terraform"]
}

variable "proxmox_datastore_id" {
  type        = string
  description = "Proxmox Datastore ID where VM disks are stored"
  default     = "local-lvm"
}

variable "vm_fixed_ip" {
  type        = string
  description = "Fixed IP address with CIDR notation for the created VM"
  default     = "192.168.0.3/24"
}

variable "vm_fixed_gateway" {
  type        = string
  description = "Fixed Gateway IP address for the created VM"
  default     = "192.168.0.1"
}

variable "vm_fixed_dns" {
  type        = list(string)
  description = "Fixed DNS server IP addresses for the created VM"
  default     = ["192.168.0.1"]
}

variable "cpu_core_count" {
  type        = number
  description = "Number of CPU cores for the created VM"
  default     = 1
  validation {
    condition     = var.cpu_core_count >= 1 && var.cpu_core_count <= 8
    error_message = "CPU core count must be at least 1, and at most 8."
  }
}

variable "memory_size_gb" {
  type        = number
  description = "Memory size in GB for the created VM"
  default     = 1
  validation {
    condition     = var.memory_size_gb >= 1 && var.memory_size_gb <= 15
    error_message = "Memory size must be at least 1 GB, and at most 15 GB."
  }
}

variable "disk_size_gb_boot" {
  type        = string
  description = "Boot disk size in GB for the created VM. Default is '16G'."
  default     = "16G"
  validation {
    condition     = tonumber(replace(var.disk_size_gb_boot, "G", "")) >= 16 && tonumber(replace(var.disk_size_gb_boot, "G", "")) <= 200
    error_message = "Boot disk size must be at least '16GB', and at most '200GB'. Also note that is a String value inside Double-Quotes with 'G' at its end."
  }
}

variable "disk_boot_ssd_enabled" {
  type        = bool
  description = "Enable SSD flag for the boot disk of the created VM"
  default     = true
  validation {
    condition     = var.disk_boot_ssd_enabled == true || var.disk_boot_ssd_enabled == false
    error_message = "disk_boot_ssd_enabled must be a boolean value (true or false)."
  }
}

locals {
  # Store the computed host IP address for reuse throughout the configuration
  host_ip = coalesce(try(split("/",proxmox_virtual_environment_vm.example.initialization[0].ip_config[0].ipv4[0].address)[0], null),proxmox_virtual_environment_vm.example.ipv4_addresses[1][0] )
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/data-sources/virtual_environment_vms
data "proxmox_virtual_environment_vms" "debian13_templates" {
  tags = var.proxmox_vm_template_tags
  node_name="jupyter"
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/data-sources/virtual_environment_vm
data "proxmox_virtual_environment_vm" "debian13_template" {
  node_name = data.proxmox_virtual_environment_vms.debian13_templates.vms[0].node_name
  vm_id     = data.proxmox_virtual_environment_vms.debian13_templates.vms[0].vm_id
}

# the virtual machine cloudbase-init cloud-config.
# NB the parts are executed by their declared order.
# see https://github.com/cloudbase/cloudbase-init
# see https://cloudbase-init.readthedocs.io/en/1.1.6/userdata.html#cloud-config
# see https://cloudbase-init.readthedocs.io/en/1.1.6/userdata.html#userdata
# see https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config.html
# see https://developer.hashicorp.com/terraform/language/expressions#string-literals
data "cloudinit_config" "example" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "initialize-disks.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      
      echo "${var.superuser_username} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${var.superuser_username}
      sudo chmod 0440 /etc/sudoers.d/${var.superuser_username}
      
      # Identify all disks without partitions and initialize them for LVM
      echo "Starting non-boot disk initialization for LVM..."
      n=2
      for disk in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}'); do
        if ! lsblk /dev/$disk | grep -q part; then
          echo "Found raw disk: /dev/$disk"
      
          # Create an MBR partition table
          parted -s /dev/$disk mklabel msdos
      
          # Create a single primary partition that spans the entire disk
          parted -s /dev/$disk mkpart primary ext4 0% 100%
      
          # Wait for the kernel to re-read partition table
          partprobe /dev/$disk
      
          # Prepare the partition for LVM (create PV)
          pvcreate /dev/$${disk}1
      
          # Optional: add to VG (example: vgname)
          vgcreate my_vg_edisk$n /dev/$${disk}1
          ((n++))
      
          echo "Initialized /dev/$${disk}1 for LVM"
        fi
      done
      echo "... Non-boot disk initialization for LVM completed."
      EOF
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_file" "example_ci_user_data" {
  content_type = "snippets"
  datastore_id = var.proxmox_datastore_id
  node_name    = var.proxmox_node_name
  source_raw {
    file_name = "${var.prefix}-ci-user-data.txt"
    data      = data.cloudinit_config.example.rendered
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "example" {
  name      = var.prefix
  node_name = var.proxmox_node_name
  tags      = var.proxmox_vm_tags
  clone {
    vm_id = data.proxmox_virtual_environment_vm.debian13_template.vm_id
    full  = true
  }
  cpu {
    type  = "host"
    #type  = "x86-64-v2-AES"
    cores = var.cpu_core_count 
  }
  memory {
    dedicated = 1024 * var.memory_size_gb
  }
  network_device {
    bridge = "vmbr0"
  }
  disk {      # Boot Disk, Size can be increased here. Then manually Increase Volume size inside Windows-2025.
    datastore_id = var.proxmox_datastore_id
    interface   = "scsi0"
    file_format = "raw"
    iothread    = true
    ssd         = var.disk_boot_ssd_enabled
    discard     = "on"
    size        = tonumber(replace(var.disk_size_gb_boot, "G", ""))
  }
  ## Add additional Disks here, if required.
  ##
  ##
  # disk {      # Boot Disk, Size can be increased here. Then manually Increase Volume size inside Windows-2025.
  #   datastore_id = var.proxmox_datastore_id
  #   interface   = "scsi1"
  #   file_format = "raw"
  #   iothread    = true
  #   ssd         = true
  #   discard     = "on"
  #   size        = 16     # minimum size of the Template image disk.
  # }

  agent {
    enabled = true
    #trim    = true
  }
  # NB we use a custom user data because this terraform provider initialization
  #    block is not entirely compatible with cloudbase-init (the cloud-init
  #    implementation that is used in the windows base image).
  # see https://pve.proxmox.com/wiki/Cloud-Init_Support
  # see https://cloudbase-init.readthedocs.io/en/latest/services.html#openstack-configuration-drive
  # see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/resources/virtual_environment_vm#initialization
  initialization {
    user_data_file_id = proxmox_virtual_environment_file.example_ci_user_data.id
    datastore_id = var.proxmox_datastore_id    
    # # >>> Fixed IP -- Start
    # # Use following if need fixed IP Address, otherwise comment out
    ip_config {
      ipv4 {
        address = var.vm_fixed_ip
        gateway = var.vm_fixed_gateway
      }
    }
    dns {
      servers = var.vm_fixed_dns
    }
    # # >>> Fixed IP -- End
  }
}

resource "time_sleep" "wait_1_minutes" {
  depends_on = [proxmox_virtual_environment_vm.example]
  # 12 minutes sleep. I have a slow Proxmox Host :(
  create_duration = "1m"
}

# # NB this can only connect after about 3m15s (because the ssh service in the
# #    windows base image is configured as "delayed start").
resource "null_resource" "ssh_into_vm" {
  depends_on = [time_sleep.wait_1_minutes]
  provisioner "remote-exec" {
    connection {
      target_platform = "unix"
      type            = "ssh"
      host            = local.host_ip
      user            = var.superuser_username
      password        = var.superuser_old_password
      private_key = file("${var.pvt_key_file}")
      agent = false
      timeout = "2m"
    }
    # NB this is executed as a batch script by cmd.exe.
    inline = [
      <<-EOF
      echo "Sucessfully logged in as user: '$(whoami)'";
      echo "Resetting password expiration...";
      echo "${var.superuser_username}:${var.superuser_new_password}" | sudo chpasswd;
      sudo chage -I -1 -m 0 -M -1 -E -1 ${var.superuser_username};
      echo "Resetting 'root' password expiration...";
      echo "root:${var.root_new_password}" | sudo chpasswd;
      sudo chage -I -1 -m 0 -M -1 -E -1 root;
      echo "Configuring passwordless sudo for ${var.superuser_username}...";
      echo "${var.superuser_username} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${var.superuser_username};
      sudo chmod 0440 /etc/sudoers.d/${var.superuser_username};
      echo "Password reset and sudo configuration completed";
      USERID="${var.superuser_username}";
      BASHRC="/home/${var.superuser_username}/.bashrc";
      if [ -d "/home/${var.superuser_username}" ] && [ -f "$BASHRC" ]; then
        grep -q "/usr/sbin" "$BASHRC" || echo 'export PATH="/usr/sbin:$PATH"' >> "$BASHRC"
        echo "Added /usr/sbin to user PATH variable"
      fi;
      gnome-extensions enable dash-to-dock@micxgx.gmail.com
      echo "Enabled dash-to-dock extension for user."
      # Set dock position to LEFT
      gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
      # Make the dock extend to full height (panel-like)
      gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
      # Disable autohide if you want it always visible
      gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
      # Enable Intellihide
      gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
      # Optional: Set fixed icon size
      gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
      # Optional: Make background fully opaque
      gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
      gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.4
      echo "Dash to Dock configured as a left-side panel."
      # Set Windows Buttons
      gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
      echo "Window buttons updated: minimize and maximize enabled."
      # Fix Flathub inclusion in gnome-software app for user
      #gnome-software --quit
      flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      echo "Fixed Flathub inclusion in gnome-software App store for User"
      # Set Hostname to prefix
      echo "Setting hostname to ${var.prefix}"
      sudo hostnamectl set-hostname ${var.prefix}
      sudo sed -i 's/127.0.1.1\s\+debian/127.0.1.1\t${var.prefix}/' /etc/hosts
      ## For debian13-cli - Fix dns, Disable ipv6
      ##
      echo "Setting DNS servers to ${join(" ", var.vm_fixed_dns)}"
      sudo bash -c 'cat > /etc/resolv.conf << EOL
      nameserver ${join("\nnameserver ", var.vm_fixed_dns)}
      EOL'
      echo "Disabling IPv6..."
      sudo bash -c 'cat >> /etc/sysctl.d/99-disable-ipv6.conf << EOL
      net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      net.ipv6.conf.lo.disable_ipv6 = 1
      EOL'
      sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
      ##
      ## End dns and ipv6 fix
      ##
      ## Extend Root filesystem to fill boot disk
      ##
      echo "Extending root filesystem to fill boot disk..."
      sudo growpart /dev/sda 3
      sudo pvresize /dev/sda3
      sudo lvextend -l +100%FREE /dev/debian-vg/root
      sudo resize2fs /dev/debian-vg/root
      echo "Extended root filesystem to fill boot disk."
      ## End Extend Root filesystem to fill boot disk
      ## Enable Docker Service to start at boot
      ##
      echo "Enabling Docker service to start at boot..."
      sudo systemctl enable docker
      echo "Enabled Docker service to start at boot."
      ## End Enable Docker Service to start at boot 
      EOF
    ]
  }
}

resource "time_sleep" "wait_3_minutes" {
  depends_on = [null_resource.ssh_into_vm]
  # 12 minutes sleep. I have a slow Proxmox Host :(
  create_duration = "3m"
}

resource "null_resource" "wait_4_apt" {
  depends_on = [time_sleep.wait_3_minutes]
  provisioner "remote-exec" {
    connection {
      target_platform = "unix"
      type            = "ssh"
      host            = local.host_ip
      user            = var.superuser_username
      password        = var.superuser_new_password
      private_key     = file("${var.pvt_key_file}")
      agent           = false
      timeout         = "5m"
    }
    inline = [
      # Wait until no apt/dpkg lock is present
      "for i in {1..300}; do sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || break; sleep 2; done",
      "for i in {1..300}; do sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || break; sleep 2; done",
      "for i in {1..300}; do sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1 || break; sleep 2; done"
    ]
  }
}

resource "null_resource" "restart_vm" {
  depends_on = [null_resource.wait_4_apt]
  provisioner "remote-exec" {
    connection {
      target_platform = "unix"
      type            = "ssh"
      host            = local.host_ip
      user            = var.superuser_username
      password        = var.superuser_new_password
      private_key = file("${var.pvt_key_file}")
      agent = false
      timeout = "2m"
    }
    # NB this is executed as a batch script by cmd.exe.
    inline = [
      <<-EOF
      sudo reboot
      EOF
    ]
  }
}


resource "time_sleep" "wait_3_minutes_2" {
  depends_on = [null_resource.restart_vm]
  create_duration = "3m"
}

/* 
## Example of copying and running a docker-compose file on the created VM.
## Assumes docker and docker-compose are already installed on the VM.
## Also assumes the docker-compose.yml file is located in ../scripts/docker-compose.yml
##
resource "null_resource" "copy_compose_file" {
  depends_on = [time_sleep.wait_3_minutes_2]
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ../scripts/docker-compose.yml ${var.superuser_username}@${local.host_ip}:/home/${var.superuser_username}/"
  }
}

resource "null_resource" "run_docker_compose" {
  depends_on = [null_resource.copy_compose_file]
  provisioner "local-exec" {
    command = <<EOT
      ssh -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ${var.superuser_username}@${local.host_ip} "cd /home/${var.superuser_username} && sudo docker compose up -d"
    EOT
  }
}
*/

/*
## Example of copying and running a custom script on the created VM.
## Assumes the custom script is located in ../scripts/install_ahc.sh
##
resource "null_resource" "call_custom_script" {
  depends_on = [time_sleep.wait_3_minutes_2]
  provisioner "local-exec" {
    command = <<EOT
      scp -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ../scripts/install_ahc.sh ${var.superuser_username}@${local.host_ip}:/home/${var.superuser_username}/install_ahc.sh
      ssh -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ${var.superuser_username}@${local.host_ip} "chmod +x /home/${var.superuser_username}/install_ahc.sh && /home/${var.superuser_username}/install_ahc.sh"
    EOT
  }
}
*/

/*
## Example of running an Ansible playbook against the created VM.
## Assumes Ansible is installed on the local machine running Terraform.
## Also assumes the Ansible playbook is located in ../scripts/ansible_main.yml
##
resource "null_resource" "run_ansible_playbook" {
  depends_on = [time_sleep.wait_3_minutes_2]
  provisioner "local-exec" {
    #interpreter = ["/bin/bash"]
    working_dir = "../scripts"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u '${var.superuser_username}' -i '${local.host_ip},' --private-key ${var.pvt_key_file} -e 'pub_key=${var.pub_key_file}' ansible_main.yml"
  }
}
*/

output "ip" {
  value = local.host_ip
  #proxmox_virtual_environment_vm.example.ipv4_addresses[index(proxmox_virtual_environment_vm.example.network_interface_names, "Ethernet")][0]
}
