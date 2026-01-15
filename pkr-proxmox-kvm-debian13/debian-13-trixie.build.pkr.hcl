build {
  sources = ["source.proxmox-iso.debian-13"]

  # Using ansible playbooks to configure debian
  provisioner "ansible" {
    playbook_file    = "./ansible/debian_config.yml"
    use_proxy        = false
    user             = "root"
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments  = ["--extra-vars", "ansible_password=${var.debian_root_password}"]
  }

  # Copy default cloud-init config
  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source      = "http/cloud.cfg"
  }

  # Replace superuser_name placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["sed -i \"s/{superuser_name}/$SUPERUSER_NAME/g\" /etc/cloud/cloud.cfg"]
    environment_vars = ["SUPERUSER_NAME=${var.superuser_name}"]
  }

  # Replace superuser_gecos placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["sed -i \"s/{superuser_gecos}/$SUPERUSER_GECOS/g\" /etc/cloud/cloud.cfg"]
    environment_vars = ["SUPERUSER_GECOS=${var.superuser_gecos}"]
  }

  # Replace superuser_password placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["sed -i \"s/{superuser_password}/$SUPERUSER_PASSWORD/g\" /etc/cloud/cloud.cfg"]
    environment_vars = ["SUPERUSER_PASSWORD=${var.superuser_password}"]
  }  

  # Replace superuser_ssh_pub_key placeholder in cloud.cfg
  provisioner "shell" {
    inline = ["sed -i \"s/{superuser_ssh_pub_key}/$SUPERUSER_SSH_PUB_KEY/g\" /etc/cloud/cloud.cfg"]
    environment_vars = ["SUPERUSER_SSH_PUB_KEY=${var.superuser_ssh_pub_key}"]
  }

  # Copy Proxmox cloud-init config
  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg.d/99-pve.cfg"
    source      = "http/99-pve.cfg"
  }
}
