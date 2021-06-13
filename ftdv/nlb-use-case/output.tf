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

output "ftd1_metadata" {
  value = [oci_core_instance.ftd-vms[0].*.metadata]
}

output "ftd2_metadata" {
    value = [oci_core_instance.ftd-vms[1].*.metadata]
}

output "ftd1_fmc_nat_id" {
  value = ["cisco123nat1"]
}

output "ftd2_fmc_nat_id" {
    value = ["cisco123nat2"]
}

output "ftd1_fmc_reg_key" {
  value = ["cisco123reg1"]
}

output "ftd2_fmc_reg_key"{
    value = ["cisco123reg2"]
}

output "admin_password_for_ssh_ftds"{
    value = ["Cisco@1234"]
}

output "initial_instruction" {
value = <<EOT
1.  Open an SSH client.
2.  Use the following information to connect to the FMC instance
username: admin
IP_Address: ${oci_core_instance.cisco-fmc.0.public_ip}
SSH Key
For example:
$ ssh –i id_rsa admin@${oci_core_instance.cisco-fmc.0.public_ip}
3.  Set the user password for the administrator. 

After setting the password, you should be able to connect to Cisco FMC UI using admin/<password_set>:
1.  In a web browser, 
    - Connect to the Cisco FMC: https://${oci_core_instance.cisco-fmc.0.public_ip}
2.  For additional details follow the official documentation to configure and manage FTDv.
    - Configuration Guide: https://www.cisco.com/c/en/us/td/docs/security/firepower/quick_start/oci/ftdv-oci-gsg.pdf 
EOT
}
