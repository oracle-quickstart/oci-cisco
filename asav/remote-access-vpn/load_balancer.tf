# ------ Network Load Balancer Cisco Untrust Interface 
resource "oci_network_load_balancer_network_load_balancer" "external_nlb" {
  depends_on     = [oci_core_network_security_group.nsg-outside]
  compartment_id = var.compute_compartment_ocid

  subnet_id = local.use_existing_subnet ? var.outside_subnet_id : oci_core_subnet.outside_subnet.0.id

  is_preserve_source_destination = false
  display_name                   = "OCNAv2-VPN"
  is_private                     = false
}

#---------- NLB Backend
resource "oci_network_load_balancer_backend_set" "external-lb-backend" {
  name                     = "ASAv-backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  policy                   = "TWO_TUPLE"
  health_checker {
    protocol           = "HTTPS"
    port               = "443"
    interval_in_millis = "10000"
    timeout_in_millis  = "3000" 
    retries            = "3"
    return_code        = "200"
  }
  
  is_preserve_source = true
}

#------------- NLB Listener
resource "oci_network_load_balancer_listener" "external-lb-listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  name                     = "ASAv-VPN"
  default_backend_set_name = oci_network_load_balancer_backend_set.external-lb-backend.name
  port                     = "0"
  protocol                 = "ANY"
}

# ------------ NLB Backend ASAv #1
resource "oci_network_load_balancer_backend" "external-public-lb-ends01" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.external-lb-backend.name
  port                     = "0"
  target_id = data.oci_core_private_ips.asav_outside_private_ips[0].private_ips[0].id
}

# ------------ NLB Backend ASAv #2
resource "oci_network_load_balancer_backend" "external-public-lb-ends02" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.external-lb-backend.name
  port                     = "0"
  target_id = data.oci_core_private_ips.asav_outside_private_ips[1].private_ips[0].id
}
