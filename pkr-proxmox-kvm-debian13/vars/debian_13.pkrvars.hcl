proxmox_host      = "10.0.0.10:8006"
proxmox_node      = "shackvm01"
vm_name           = "template-debian-13-docker"
vmid              = "9000"
cpu_type          = "host"
cores             = "2"
memory            = "2048"
storage_pool      = "local-lvm"
disk_size         = "16G"
disk_format       = "raw"

iso_file         = "local:iso/debian-13.0.0-amd64-netinst.iso"
iso_checksum     = "sha512:069d47e9013cb1d651d30540fe8ef6765e5d60c8a14c8854dfb82e50bbb171255d2e02517024a392e46255dcdd18774f5cbd7e9f3a47aa1b489189475de62675"
iso_storage_pool = "local:iso"

# it is hard coded in preseed cfg
debian_root_password = "packer"
preseed_url = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg"