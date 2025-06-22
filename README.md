# proxmox-kvm-debian12

Debian12 Gnome Desktop VM Packer Builder and Terraform Instance Manager scripts. Previously these scripts were located in 2 different projects.
There are two parts to it.
1. Using Packer, Ansible, Proxmox etc. create a local KVM Template for Debian12.
    - It is in the subfolder begining with pkr-*
1. Using Terraform, and possibly Ansible, create an Instance of that Image for actual usage.
    - It is in subfolder begining with tf-*

## Usage
1. Preparing for Image Build
    1. For faster build times, the ISO was pre-downloaded into Proxmox server. The Debian12 Source code binary(iso) used in the Packer script was downloaded from following, and its SHA512 Sum link.
        - General Repo Page, scroll to the bottom to see the artifacts. [https://get.debian.org/images/release/12.11.0/amd64/iso-cd/](https://get.debian.org/images/release/12.11.0/amd64/iso-cd/)
        - ISO Link - [https://get.debian.org/images/release/12.11.0/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso](https://get.debian.org/images/release/12.11.0/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso)
        - SHA512 Sum Link - [https://get.debian.org/images/release/12.11.0/amd64/iso-cd/SHA512SUMS](https://get.debian.org/images/release/12.11.0/amd64/iso-cd/SHA512SUMS)
    1. An actual WebServer was available and used in Packer Preseeding, rather then using the default Packer mechanism of inbuilt temporary webserver.
        - To do the same for yourself, just copy all files in the subfolder ./pkr-proxmox-kvm-debian12/http to the actual webserver. Then change the ./pkr-proxmox-kvm-debian12/vars/debian_12.pkrvars.hcl file accordingly.
1. Image (KVM Template)  Build 
    1. Change Directory into ./pkr-proxmox-kvm-debian12
        ```
        cd ./pkr-proxmox-kvm-debian12
        ```
    1. Initialize Packer.
        ```
        packer init .
        ```
    1. Launch Packer Build of Image (KVM Template) with your custom parameters or the Default sample.
        ```
        packer build -var-file vars/debian12-hammad.pkrvars.hcl -var "proxmox_api_password=Password#01" .
        --- OR ---
        packer build -var-file vars/debian12.pkrvars.hcl -var "proxmox_api_password=Stupido@2017" .
        ```
    1. The Image (KVM Template) should now be ready on the Proxmox server.
1. VM Instance Creation
    1. Change Directory into ../tf-proxmox-kvm-debian12
        ```
        cd ../tf-proxmox-kvm-debian12
        ```
    1. Note that the Terraform script (coming up next) uses the Tags to identify the Image (KVM Template). So if you have changed the tags in the Packer configuration, you should also change them in the Terraform configuration.
    1. Launch Terraform to create an Instance of this Image, that you will actually use.
        ```
        terraform init
        terraform plan
        terraform apply -auto-approve
        ```
    1. Your instance VM should now be ready.
    1. You will need to log-in using SSH atleast once to change the template-assigned random password for the Super-User.
        ```
        ssh terraform@<<IP_Address_of_instance>>
        ```
        - Once logged in Change the Super-user password by using the following command interactivley:
            ```
            sudo passwd terraform
            ```
    1. Now you can use RDP client to start a Desktop session with your instance.
    1. To Destroy the Instance use the following command, in the ./tf-proxmox-kvm-debian12 folder:
        ```
        terraform destroy -auto-approve
        ```
  



