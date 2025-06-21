proxmox_host      = "10.0.0.10:8006"
proxmox_node      = "shackvm01"
vm_name           = "template-debian-12-docker"
vmid              = "9000"
cpu_type          = "host"
cores             = "2"
memory            = "2048"
storage_pool      = "local-lvm"
disk_size         = "16G"
disk_format       = "raw"

iso_file         = "local:iso/debian-12.11.0-amd64-netinst.iso"
iso_checksum     = "sha512:0921d8b297c63ac458d8a06f87cd4c353f751eb5fe30fd0d839ca09c0833d1d9934b02ee14bbd0c0ec4f8917dde793957801ae1af3c8122cdf28dde8f3c3e0da"
iso_storage_pool = "local:iso"

# it is hard coded in preseed cfg
debian_root_password = "packer"
preseed_url = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg"