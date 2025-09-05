# Packer Debian 13 (Trixie) Template for Proxmox
Packer configuration for creating Debian 13 virtual machine templates for Proxmox VE.

## Original Work Acknowledgement
This Packer builder is heavily derived from the original work done at [https://github.com/shackofnoreturn/packer-proxmox-debian-12-bookworm-template](https://github.com/shackofnoreturn/packer-proxmox-debian-12-bookworm-template)

## Requirements
- [Packer](https://www.packer.io/downloads)
- [Proxmox VE](https://www.proxmox.com/en/proxmox-ve)

## Why
Time and time again you create a VM and go through the setup manually.
This method automatically goes through all manual options using a preseed.

More info on preseeding: [preseed documentation](https://wiki.debian.org/DebianInstaller/Preseed)

## How
### 1. Authorized Keys
If you don't have one already. Create a new keypair.

```sh
ssh-keygen
```

I've just saved the key to the default location and left the passphrase empty.
After doing that you'll find your private (id_rsa) and public keys (id_rsa.pub) in your profile .ssh directory. (/Users/**YourUsername**/.ssh)

Copy the contents of your public key file and paste it in cloud.cfg
Replace or remove the example if you need to.

### 2. Creating a new VM Template
Templates are created by converting an existing VM to a template.
Navigate to the project directory and execute the following command:

```sh
packer init .
#packer build -var-file vars/debian_13.pkrvars.hcl -var "proxmox_api_password=PASSWORD_HERE" .
packer build -var-file vars/debian13-hammad.pkrvars.hcl -var "proxmox_api_password=PASSWORD_HERE" .
```

### 3. Deploy a VM from a Template
Right-click the template in Proxmox VE, and select "Clone".

- **full clone** is a complete copy and is fully independent from the original VM or VM Template, but it requires the same disk space as the original
- **linked clone** requires less disk space but cannot run without access to the base VM Template. Not supported with LVM & ISCSI storage types


### 4. Connect with cloned VM over SSH
(*Change the IP with your new VM's IP*)

```sh
ssh shackadmin@10.0.0.226
```

The certificate should do and no further passwords are needed.
