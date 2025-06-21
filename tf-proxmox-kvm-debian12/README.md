# KVM Debian12 - Template - Notes
Proxmox VE can store Qemu KVM VM (Virtual Machine) images and LXC Container Images (CT templates) as template for quick deployment. LXC Containers (light weight VMs) share kernel with the Proxmox host, so only Linux is a possibility.

## KVM Debian12 - Minimum Requirements
- Disk size - 16 GB
- RAM - 2 GB
- TPM - true
- Cores - Minimum 2 cores - 1 GHz or faster.


## Debian12 - Gnome Desktop Customization
```
sudo apt install -y -no-install-recommends chrome-gnome-shell gnome-shell-extension-dashtodock gnome-shell-extension-manager gnome-shell-extensions gnome-shell-extensions-extra gnome-tweaks lua5.4 jq imagemagick
```

## Using Terraform to Clone Qemu VM template on Proxmox
```
terraform init
terraform plan
terraform apply -auto-approve
terrform destroy -auto-approve
```

## Terraform Apply - Errors
- Proxmox Snippets folder permission
    - Folder permissions are automatically reset after few hours
    - Permanent Fix - To Do
    - Temporary Fix:
        - SSH to Promox Host
            ```
            root@pve:~# ls -lart /var/lib/vz/snippets/
            total 16
            drwxr-xr-x 6 root           root           4096 Jun 12 16:30 ..
            drwxr-xr-x 2 root           root           4096 Jun 12 16:31 .
            root@pve:~# chmod -R 775 /var/lib/vz/snippets/
            root@pve:~# ls -lart /var/lib/vz/snippets/
            total 16
            drwxr-xr-x 6 root           root           4096 Jun 12 16:30 ..
            drwxrwxr-x 2 root           root           4096 Jun 12 16:31 .
            ```

