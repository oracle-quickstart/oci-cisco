output "initial_instruction" {
value = <<EOT

Follow the instructions below to test the environment:

1.  Using AnyConnect navigate to the following link to test VPN access. You you currently do not have AnyConnect to the URL in the browser to download it: 

      Connect to the Load Balancer VIP: https://${oci_network_load_balancer_network_load_balancer.external_nlb.ip_addresses[0].ip_address}: 
EOT  
}

