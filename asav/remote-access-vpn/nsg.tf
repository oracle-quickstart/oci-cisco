# ---------- Create Outside Network Security Group
resource "oci_core_network_security_group" "nsg-outside" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.outside[count.index].id
  display_name = "nsg-outside"
}

resource "oci_core_network_security_group_security_rule" "outside-rule_ingress_TCP_VPN" {
  count                     = local.use_existing_subnet ? 0 : 1
  network_security_group_id = oci_core_network_security_group.nsg-outside.0.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "outside-rule_ingresss_UDP_VPN" {
  count                     = local.use_existing_subnet ? 0 : 1
  network_security_group_id = oci_core_network_security_group.nsg-outside.0.id
  direction                 = "INGRESS"
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  udp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
  }
}