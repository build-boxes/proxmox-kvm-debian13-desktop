build {
  sources = ["source.proxmox-iso.debian-13"]

  # Using ansible playbooks to configure debian
  provisioner "ansible" {
    playbook_file    = "./ansible/debian_config.yml"
    use_proxy        = false
    user             = "root"
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments  = ["--extra-vars", "ansible_password=${var.debian_root_password} superuser_name=${var.superuser_name}"]
  }

  # Copy default cloud-init config
  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source      = "http/cloud.cfg"
  }

  # Replace superuser_name placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["awk -v old='<<superuser_name>>' -v new='${var.superuser_name}' '{gsub(old, new); print}' /etc/cloud/cloud.cfg > /tmp/cloud.cfg && mv /tmp/cloud.cfg /etc/cloud/cloud.cfg"]
  }

  # Replace superuser_gecos placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["awk -v old='<<superuser_gecos>>' -v new='${var.superuser_gecos}' '{gsub(old, new); print}' /etc/cloud/cloud.cfg > /tmp/cloud.cfg && mv /tmp/cloud.cfg /etc/cloud/cloud.cfg"]
  }

  # Replace superuser_password placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["awk -v old='<<superuser_password>>' -v new='${var.superuser_password}' '{gsub(old, new); print}' /etc/cloud/cloud.cfg > /tmp/cloud.cfg && mv /tmp/cloud.cfg /etc/cloud/cloud.cfg"]
  }

  # Replace superuser_ssh_pub_key placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["awk -v old='<<superuser_ssh_pub_key>>' -v new='${var.superuser_ssh_pub_key}' '{gsub(old, new); print}' /etc/cloud/cloud.cfg > /tmp/cloud.cfg && mv /tmp/cloud.cfg /etc/cloud/cloud.cfg"]
  }

  # Copy Proxmox cloud-init config
  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg.d/99-pve.cfg"
    source      = "http/99-pve.cfg"
  }
}
