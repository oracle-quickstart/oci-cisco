# ------ Network Load Balancer Firewall - Public NLB 
resource "oci_network_load_balancer_network_load_balancer" "external_nlb" {
  compartment_id = var.network_compartment

  subnet_id = oci_core_subnet.nlb_subnet.id

  is_preserve_source_destination = true
  display_name                   = "CiscoExternalPublicNLB"
  is_private                     = false
}

# ------ Network Load Balancer Firewall - Public NLB's Backend Set
resource "oci_network_load_balancer_backend_set" "external-lb-backend" {
  name                     = "external-lb-backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  policy                   = "FIVE_TUPLE"
  health_checker {
    port     = "22"
    protocol = "TCP"
  }
}

# ------ Network Load Balancer Firewall - Public NLB's Listener
resource "oci_network_load_balancer_listener" "external-lb-listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  name                     = "firewall-untrust"
  default_backend_set_name = oci_network_load_balancer_backend_set.external-lb-backend.name
  port                     = "0"
  protocol                 = "ANY"
}

# ------ Network Load Balancer Firewall - Public NLB's Backend Set's Backend 1
resource "oci_network_load_balancer_backend" "external-public-lb-ends01" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.external-lb-backend.name
  port                     = "0"
  target_id                = data.oci_core_private_ips.outside_subnet_public_ips.private_ips[0].id
}

# ------ Network Load Balancer Firewall - Public NLB's Backend Set's Backend 2
resource "oci_network_load_balancer_backend" "external-public-lb-ends02" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.external-lb-backend.name
  port                     = "0"
  target_id                = data.oci_core_private_ips.outside_subnet_public_ips.private_ips[1].id
}

# ------ Network Load Balancer Firewall - Private On Prem NLB 
resource "oci_network_load_balancer_network_load_balancer" "external_private_nlb" {
  compartment_id = var.network_compartment
  subnet_id      = oci_core_subnet.nlb_subnet.id

  is_preserve_source_destination = true
  display_name                   = "CiscoExternalPrivateNLB"
  is_private                     = true
}

# ------ Network Load Balancer Firewall - Private On Prem NLB's Backend Set
resource "oci_network_load_balancer_backend_set" "external-private-lb-backend" {
  name                     = "external-private-lb-backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_private_nlb.id
  policy                   = "FIVE_TUPLE"
  health_checker {
    port     = "22"
    protocol = "TCP"
  }
}

# ------ Network Load Balancer Firewall - Private On Prem NLB's Listener
resource "oci_network_load_balancer_listener" "external-private-lb-listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_private_nlb.id
  name                     = "firewall-untrust"
  default_backend_set_name = oci_network_load_balancer_backend_set.external-private-lb-backend.name
  port                     = "0"
  protocol                 = "ANY"
}

# ------ Network Load Balancer Firewall - Private On Prem NLB's Backend Set's Backend 1
resource "oci_network_load_balancer_backend" "external-private-lb-ends01" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_private_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.external-private-lb-backend.name
  port                     = "0"
  target_id                = data.oci_core_private_ips.outside_subnet_public_ips.private_ips[0].id
}

# ------ Network Load Balancer Firewall - Private On Prem NLB's Backend Set's Backend 2
resource "oci_network_load_balancer_backend" "external-private-lb-ends02" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external_private_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.external-private-lb-backend.name
  port                     = "0"
  target_id                = data.oci_core_private_ips.outside_subnet_public_ips.private_ips[1].id
}

# ------ Network Load Balancer Firewall - Private NLB 
resource "oci_network_load_balancer_network_load_balancer" "internal_nlb" {
  compartment_id                 = var.network_compartment
  subnet_id                      = data.oci_core_subnets.dmz_vcn_subnets_indoor.subnets.0.id
  is_preserve_source_destination = true
  display_name                   = "CiscoInternalNLB"
  is_private                     = true
}

# ------ Network Load Balancer Firewall - Private NLB's Backend Set
resource "oci_network_load_balancer_backend_set" "internal-lb-backend" {
  name                     = "internal-lb-backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.internal_nlb.id
  policy                   = "FIVE_TUPLE"
  health_checker {
    port     = "22"
    protocol = "TCP"
  }
}

# ------ Network Load Balancer Firewall - Private NLB's Listener
resource "oci_network_load_balancer_listener" "internal-lb-listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.internal_nlb.id
  name                     = "firewall-trust"
  default_backend_set_name = oci_network_load_balancer_backend_set.internal-lb-backend.name
  port                     = "0"
  protocol                 = "ANY"
}

# ------ Network Load Balancer Firewall - Private NLB's Backend Set's Backend 1
resource "oci_network_load_balancer_backend" "internal-lb-ends01" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.internal_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.internal-lb-backend.name
  port                     = "0"
  target_id                = data.oci_core_private_ips.inside_subnet_private_ips.private_ips[0].id
}

# ------ Network Load Balancer Firewall - Private NLB's Backend Set's Backend 2
resource "oci_network_load_balancer_backend" "internal-lb-ends02" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.internal_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.internal-lb-backend.name
  port                     = "0"
  target_id                = data.oci_core_private_ips.inside_subnet_private_ips.private_ips[1].id
}
