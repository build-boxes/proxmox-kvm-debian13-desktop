resource "null_resource" "configure_muezzin_p1" {
  depends_on = [time_sleep.wait_3_minutes_2]
  provisioner "local-exec" {
    command = <<EOT
        scp -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ../scripts/configure_muezzin_p1.sh ${var.superuser_username}@${local.host_ip}:/home/${var.superuser_username}/configure_muezzin_p1.sh
        ssh -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ${var.superuser_username}@${local.host_ip} "chmod +x /home/${var.superuser_username}/configure_muezzin_p1.sh"
        ssh -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ${var.superuser_username}@${local.host_ip} "bash /home/${var.superuser_username}/configure_muezzin_p1.sh \
            ${var.superuser_username} \
            ${local.config_file} \
            ${var.calc_method} \
            ${var.madhab} \
            ${var.latitude} \
            ${var.longitude} \
            ${var.timezone} \
            ${var.startup_sound} \
            ${var.fajr_custom} \
            ${var.fajr_url} \
            ${var.dua_enabled}"
    EOT
  }
}

resource "null_resource" "restart_vm2" {
  depends_on = [null_resource.configure_muezzin_p1]
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

resource "time_sleep" "wait_3p5_minutes" {
  depends_on = [null_resource.restart_vm2]
  create_duration = "210s"
}

resource "null_resource" "configure_muezzin_p2" {
  depends_on = [time_sleep.wait_3p5_minutes]
  provisioner "local-exec" {
    command = <<EOT
        scp -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ../scripts/configure_muezzin_p2.sh ${var.superuser_username}@${local.host_ip}:/home/${var.superuser_username}/configure_muezzin_p2.sh
        ssh -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ${var.superuser_username}@${local.host_ip} "chmod +x /home/${var.superuser_username}/configure_muezzin_p2.sh"
        ssh -o StrictHostKeyChecking=no -i ${var.pvt_key_file} ${var.superuser_username}@${local.host_ip} "bash /home/${var.superuser_username}/configure_muezzin_p2.sh \
            ${var.superuser_username} \
            ${local.config_file} \
            ${var.calc_method} \
            ${var.madhab} \
            ${var.latitude} \
            ${var.longitude} \
            ${var.timezone} \
            ${var.startup_sound} \
            ${var.fajr_custom} \
            ${var.fajr_url} \
            ${var.dua_enabled}"
    EOT
  }
}
