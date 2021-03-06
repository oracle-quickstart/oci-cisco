# ---- Create VCN Ingress Route Table on Hub VCN
resource "oci_core_route_table" "vcn_ingress_route_table" {
  compartment_id = var.network_compartment
  vcn_id         = var.firewall_vcn
  display_name   = "${local.dmz_vcn_name}-ingress-rtable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

  route_rules {
    destination       = var.vcn_cidrs[0]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

  route_rules {
    destination       = var.vcn_cidrs[1]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

}

# ------ Attach DRG to Hub VCN
resource "oci_core_drg_attachment" "hub_drg_attachment" {
  drg_id = var.drg_ocid
  # vcn_id             = local.use_existing_network ? var.vcn_id : oci_core_vcn.hub.0.id
  display_name       = "Firewall_VCN"
  drg_route_table_id = oci_core_drg_route_table.from_firewall_route_table.id

  network_details {
    id             = var.firewall_vcn
    type           = "VCN"
    route_table_id = oci_core_route_table.vcn_ingress_route_table.id
  }
}

# ------ Attach DRG to Web Spoke VCN
resource "oci_core_drg_attachment" "web_drg_attachment" {
  drg_id             = var.drg_ocid
  vcn_id             = var.db_vcn
  display_name       = "Web_VCN"
  drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
}

# ------ Attach DRG to DB Spoke VCN
resource "oci_core_drg_attachment" "db_drg_attachment" {
  drg_id             = var.drg_ocid
  vcn_id             = var.web_vcn
  display_name       = "DB_VCN"
  drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
}

# ------ Create From Firewall Route Table to DRG
resource "oci_core_drg_route_table" "from_firewall_route_table" {
  drg_id                           = var.drg_ocid
  display_name                     = "From-Firewall"
  import_drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
}

# ------ Create To Firewall Route Table to DRG
resource "oci_core_drg_route_table" "to_firewall_route_table" {
  drg_id       = var.drg_ocid
  display_name = "To-Firewall"
}

# ---- Update To Firewall Route Table Pointing to Hub VCN 
resource "oci_core_drg_route_table_route_rule" "to_firewall_drg_route_table_route_rule" {
  drg_route_table_id         = oci_core_drg_route_table.to_firewall_route_table.id
  destination                = "0.0.0.0/0"
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = oci_core_drg_attachment.hub_drg_attachment.id
}

# ---- DRG Route Import Route Distribution
resource "oci_core_drg_route_distribution" "firewall_drg_route_distribution" {
  distribution_type = "IMPORT"
  drg_id            = var.drg_ocid
  display_name      = "Transit-Spokes"
}

# ---- DRG Route Import Route Distribution Statements - One
resource "oci_core_drg_route_distribution_statement" "firewall_drg_route_distribution_statement_one" {
  drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
  action                    = "ACCEPT"
  match_criteria {
    match_type        = "DRG_ATTACHMENT_ID"
    drg_attachment_id = oci_core_drg_attachment.web_drg_attachment.id
  }
  priority = "1"
}

# ---- DRG Route Import Route Distribution Statements - Two 
resource "oci_core_drg_route_distribution_statement" "firewall_drg_route_distribution_statement_two" {
  drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
  action                    = "ACCEPT"
  match_criteria {
    match_type        = "DRG_ATTACHMENT_ID"
    drg_attachment_id = oci_core_drg_attachment.db_drg_attachment.id
  }
  priority = "2"
}


# ------ Create Firewall/Hub VCN NLB subnet
resource "oci_core_subnet" "nlb_subnet" {
  compartment_id             = var.network_compartment
  vcn_id                     = var.firewall_vcn
  cidr_block                 = var.nlb_subnet_cidr_block
  display_name               = "${local.dmz_vcn_name}-nlb-subnet"
  route_table_id             = oci_core_route_table.nlb_route_table.id
  dns_label                  = var.nlb_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_all_security,
  ]
}

# ------ Create Default Security List for NLB Subnet
resource "oci_core_security_list" "allow_all_security" {
  compartment_id = var.network_compartment
  vcn_id         = var.firewall_vcn
  display_name   = "nlb_security"
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# ------ Create NLB Route Table
resource "oci_core_route_table" "nlb_route_table" {
  compartment_id = var.network_compartment
  vcn_id         = var.firewall_vcn
  display_name   = "${local.dmz_vcn_name}-nlb-subnet-rtable"

  route_rules {
    destination       = var.vcn_cidrs[0]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.drg_ocid
  }

  route_rules {
    destination       = var.vcn_cidrs[1]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.drg_ocid
  }
}
