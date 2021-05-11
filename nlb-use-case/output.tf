output "subscription" {
  value = data.oci_core_app_catalog_subscriptions.mp_image_subscription.*.app_catalog_subscriptions
}

output "firewallA_instance_public_ips" {
  value = [oci_core_instance.ftd-vms[0].*.public_ip]
}

output "firewallA_instance_private_ips" {
  value = [oci_core_instance.ftd-vms[0].*.private_ip]
}

output "firewallB_instance_public_ips" {
  value = [oci_core_instance.ftd-vms[1].*.public_ip]
}

output "firewallB_instance_private_ips" {
  value = [oci_core_instance.ftd-vms[1].*.private_ip]
}

output "instance_https_urls" {
  value = formatlist("https://%s", oci_core_instance.ftd-vms.*.public_ip)
}

output "fmc_instance_https_url" {
  value = formatlist("https://%s", oci_core_instance.cisco-fmc.0.public_ip)
}

output "fmc1_metadata" {
  value = [oci_core_instance.ftd-vms[0].*.metadata]
}

output "fmc2_metadata" {
    value = [oci_core_instance.ftd-vms[1].*.metadata]
}

output "initial_instruction" {
value = <<EOT
1.  Open an SSH client.
2.  Use the following information to connect to the instance
username: admin
IP_Address: ${oci_core_instance.ftd-vms.0.public_ip}
SSH Key
For example:
$ ssh –i id_rsa admin@${oci_core_instance.ftd-vms.0.public_ip}
3.  Set the user password for the administrator. 
    - <update_this>
4. Save the configuration. Enter the command: <update>

After saving the password, you should be able to connect to Cisco FMC UI using admin/<password_set>:
1.  In a web browser, 
    - Connect to the Cisco FTD Firewall-1: https://${oci_core_instance.ftd-vms.0.public_ip}
    - Connect to the Cisco FTD Firewall-2: https://${oci_core_instance.ftd-vms.1.public_ip}
2.  For additional details follow the official documentation.
EOT
}
