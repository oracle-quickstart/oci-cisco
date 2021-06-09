# ------ Create HUB VCN
resource "oci_core_vcn" "hub" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.vcn_cidr_block
  dns_label      = var.vcn_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.vcn_display_name
}

# ------ Create IGW
resource "oci_core_internet_gateway" "igw" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  display_name   = "${var.vcn_display_name}-igw"
  vcn_id         = oci_core_vcn.hub[count.index].id
  enabled        = "true"
}

# ------ Create DRG
resource "oci_core_drg" "drg" {
  compartment_id = var.network_compartment_ocid
  display_name   = "${var.vcn_display_name}-drg"
}

# ------ Attach DRG to Hub VCN
resource "oci_core_drg_attachment" "hub_drg_attachment" {
  drg_id = oci_core_drg.drg.id
  vcn_id = local.use_existing_network ? var.vcn_id : oci_core_vcn.hub.0.id
  display_name = "Firewall-VCN"
  drg_route_table_id = oci_core_drg_route_table.from_firewall_route_table.id
}

# ------ Attach DRG to Web Spoke VCN
resource "oci_core_drg_attachment" "web_drg_attachment" {
  drg_id = oci_core_drg.drg.id
  vcn_id = local.use_existing_network ? var.web_vcn_id : oci_core_vcn.web.0.id
  display_name = "Web-Spoke-VCN"
  drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
}

# ------ Attach DRG to DB Spoke VCN
resource "oci_core_drg_attachment" "db_drg_attachment" {
  drg_id = oci_core_drg.drg.id
  vcn_id = local.use_existing_network ? var.db_vcn_id : oci_core_vcn.db.0.id
  display_name = "DB-Spoke-VCN"
  drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
}

# ------ DRG From Firewall Route Table
resource "oci_core_drg_route_table" "from_firewall_route_table" {
    drg_id = oci_core_drg.drg.id
    display_name = "From-Firewall"
    import_drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
}

# ------ DRG to Firewall Route Table
resource "oci_core_drg_route_table" "to_firewall_route_table" {
    drg_id = oci_core_drg.drg.id
    display_name = "To-Firewall"
}

# ------ Add DRG To Firewall Route Table Entry
resource "oci_core_drg_route_table_route_rule" "to_firewall_drg_route_table_route_rule" {
    drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    next_hop_drg_attachment_id = oci_core_drg_attachment.hub_drg_attachment.id
}

# ---- DRG Route Import Distribution 
resource "oci_core_drg_route_distribution" "firewall_drg_route_distribution" {
    distribution_type = "IMPORT"
    drg_id = oci_core_drg.drg.id
    display_name = "Transit-Spokes"
}

# ---- DRG Route Import Distribution Statements - One
resource "oci_core_drg_route_distribution_statement" "firewall_drg_route_distribution_statement_one" {
    drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
    action = "ACCEPT"
    match_criteria {
    match_type = "DRG_ATTACHMENT_ID"
    # attachment_type = var.drg_route_distribution_statement_statements_match_criteria_attachment_type
    drg_attachment_id = oci_core_drg_attachment.web_drg_attachment.id
    }
    priority = "1"

}

# ---- DRG Route Import Distribution Statements - Two 
resource "oci_core_drg_route_distribution_statement" "firewall_drg_route_distribution_statement_two" {
    drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
    action = "ACCEPT"
    match_criteria {
    match_type = "DRG_ATTACHMENT_ID"
    # attachment_type = var.drg_route_distribution_statement_statements_match_criteria_attachment_type
    drg_attachment_id = oci_core_drg_attachment.db_drg_attachment.id
    }
    priority = "2"

}


# ------ Default Routing Table for Hub VCN 
resource "oci_core_default_route_table" "default_route_table" {
  count                      = local.use_existing_network ? 0 : 1
  manage_default_resource_id = oci_core_vcn.hub[count.index].default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }

  route_rules {
    destination       = "172.16.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.0.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.1.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

}

# ------ Default Routing Table for Hub VCN 
resource "oci_core_route_table" "outside_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.hub[count.index].id
  display_name   = var.public_routetable_display_name

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }

  route_rules {
    destination       = "172.16.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.0.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.1.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

# ------ Diagnostic Routing Table for Hub VCN 
resource "oci_core_route_table" "diagnostic_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.hub[count.index].id
  display_name   = var.diagnostic_routetable_display_name

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }

  route_rules {
    destination       = "172.16.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.0.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.1.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

# # ------ Create LPG Hub Route Table
resource "oci_core_route_table" "vcn_ingress_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.hub[count.index].id
  display_name   = "VCN-INGRESS"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

  route_rules {
    destination       = "10.0.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

  route_rules {
    destination       = "10.1.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

  depends_on = [
    oci_network_load_balancer_network_load_balancer.internal_nlb,
  ]
}

# ------ Create NLB Route Table
resource "oci_core_route_table" "nlb_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.hub[count.index].id
  display_name   = var.nlb_routetable_display_name

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }

  route_rules {
    destination       = "172.16.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.0.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.1.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}


# # ------ Create DRG Hub Route Table
# resource "oci_core_route_table" "drg_route_table" {
#   count          = local.use_existing_network ? 0 : 1
#   compartment_id = var.network_compartment_ocid
#   vcn_id         = oci_core_vcn.hub[count.index].id
#   display_name   = var.drg_routetable_display_name

#   route_rules {
#     destination       = "10.0.0.0/24"
#     destination_type  = "CIDR_BLOCK"
#     network_entity_id = data.oci_core_private_ips.outside_subnet_private_nlb_ip.private_ips[0].id
#   }

#   route_rules {
#     destination       = "10.1.0.0/24"
#     destination_type  = "CIDR_BLOCK"
#     network_entity_id = data.oci_core_private_ips.outside_subnet_private_nlb_ip.private_ips[0].id
#   }

#   depends_on = [
#     oci_network_load_balancer_network_load_balancer.external_nlb,
#   ]

# }

# ------ Get All Services Data Value 
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# ------ Create Hub Service Gateway (Hub VCN)
resource "oci_core_service_gateway" "hub_service_gateway" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.hub[count.index].id
  services {
    service_id = data.oci_core_services.all_services.services[0]["id"]
  }
  display_name   = "hubServiceGateway"
  route_table_id = oci_core_route_table.service_gw_route_table_transit_routing[count.index].id
}

# ------ Get Hub Service Gateway from Gateways (Hub VCN)
data "oci_core_service_gateways" "hub_service_gateways" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  state          = "AVAILABLE"
  vcn_id         = oci_core_vcn.hub[count.index].id
}

# ------ Associate Emptry Route Tables to Service Gateway on Hub VCN Floating IP
resource "oci_core_route_table" "service_gw_route_table_transit_routing" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.hub[count.index].id
  display_name   = var.sgw_routetable_display_name

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.inside_subnet_private_nlb_ip.private_ips[0].id
  }

  depends_on = [
    oci_network_load_balancer_network_load_balancer.internal_nlb,
  ]
}

# ------ Create Hub VCN Public subnet
resource "oci_core_subnet" "mangement_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.hub[count.index].id
  cidr_block                 = var.mangement_subnet_cidr_block
  display_name               = var.mangement_subnet_display_name
  route_table_id             = oci_core_vcn.hub[count.index].default_route_table_id
  dns_label                  = var.mangement_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_all_security,
  ]
}

# ------ Create Hub VCN Trust subnet
resource "oci_core_subnet" "inside_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.hub[count.index].id
  cidr_block                 = var.inside_subnet_cidr_block
  display_name               = var.inside_subnet_display_name
  dns_label                  = var.inside_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security.security_lists[0].id]
  prohibit_public_ip_on_vnic = "true"

  depends_on = [
    oci_core_security_list.allow_all_security,
  ]

}

# ------ Create Hub VCN Cisco NLB subnet
resource "oci_core_subnet" "nlb_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.hub[count.index].id
  cidr_block                 = var.nlb_subnet_cidr_block
  display_name               = var.nlb_subnet_display_name
  route_table_id             = oci_core_vcn.hub[count.index].default_route_table_id
  dns_label                  = var.nlb_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_all_security,
  ]
}

# ------ Create Hub VCN Cisco Diagnostic subnet
resource "oci_core_subnet" "diagnostic_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.hub[count.index].id
  cidr_block                 = var.diagnostic_subnet_cidr_block
  display_name               = var.diagnostic_subnet_display_name
  route_table_id             = oci_core_vcn.hub[count.index].default_route_table_id
  dns_label                  = var.diagnostic_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security.security_lists[0].id]
  prohibit_public_ip_on_vnic = "true"

  depends_on = [
    oci_core_security_list.allow_all_security,
  ]
}

# ------ Update Route Table for Trust Subnet
resource "oci_core_route_table_attachment" "update_inside_route_table" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = local.use_existing_network ? var.inside_subnet_id : oci_core_subnet.inside_subnet[0].id
  route_table_id = oci_core_route_table.inside_route_table[count.index].id
}

# ------ Create Hub VCN Cisco Internet subnet
resource "oci_core_subnet" "outside_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.hub[count.index].id
  cidr_block                 = var.outside_subnet_cidr_block
  display_name               = var.outside_subnet_display_name
  route_table_id             = oci_core_route_table.outside_route_table[count.index].id
  dns_label                  = var.outside_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_all_security,
  ]
}

# ------ Create route table for backend to point to backend cluster ip (Hub VCN)
resource "oci_core_route_table" "inside_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_id : oci_core_vcn.hub[0].id
  display_name   = var.private_routetable_display_name

  route_rules {
    destination       = "10.0.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.0.1.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = data.oci_core_services.all_services.services[0]["cidr_block"]
    network_entity_id = oci_core_service_gateway.hub_service_gateway[count.index].id
  }

  depends_on = [
    # oci_core_local_peering_gateway.hub_web_local_peering_gateway,
    # oci_core_local_peering_gateway.hub_db_local_peering_gateway
  ]
}

# ------ Add Trust route table to Trust subnet (Hub VCN)
resource "oci_core_route_table_attachment" "inside_route_table_attachment" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = local.use_existing_network ? var.inside_subnet_id : oci_core_subnet.inside_subnet[0].id
  route_table_id = oci_core_route_table.inside_route_table[count.index].id
}

# ------ Create Web VCN
resource "oci_core_vcn" "web" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.web_vcn_cidr_block
  dns_label      = var.web_vcn_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.web_vcn_display_name
}

# ------ Create Web Route Table and Associate to DRG
resource "oci_core_default_route_table" "web_default_route_table" {
  count                      = local.use_existing_network ? 0 : 1
  manage_default_resource_id = oci_core_vcn.web[count.index].default_route_table_id
  route_rules {
    network_entity_id = oci_core_drg.drg.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# ------ Add Web Private Subnet to Web VCN
resource "oci_core_subnet" "web_private-subnet" {
  count                      = local.use_existing_network ? 0 : 1
  cidr_block                 = var.web_transit_subnet_cidr_block
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.web[count.index].id
  display_name               = var.web_transit_subnet_display_name
  dns_label                  = var.web_transit_subnet_dns_label
  prohibit_public_ip_on_vnic = true
}

# ------ Add Web Load Balancer Subnet to Web VCN
resource "oci_core_subnet" "web_lb-subnet" {
  count                      = local.use_existing_network ? 0 : 1
  cidr_block                 = var.web_lb_subnet_cidr_block
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.web[count.index].id
  display_name               = var.web_lb_subnet_display_name
  dns_label                  = var.web_lb_subnet_dns_label
  prohibit_public_ip_on_vnic = false
}

# ------ Create DB VCN
resource "oci_core_vcn" "db" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.db_vcn_cidr_block
  dns_label      = var.db_vcn_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.db_vcn_display_name
}

# ------ Create DB Route Table and Associate to DB LPG
resource "oci_core_default_route_table" "db_default_route_table" {
  count                      = local.use_existing_network ? 0 : 1
  manage_default_resource_id = oci_core_vcn.db[count.index].default_route_table_id
  route_rules {
    network_entity_id = oci_core_drg.drg.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# ------ Add DB Private Subnet to DB VCN
resource "oci_core_subnet" "db_private-subnet" {
  count                      = local.use_existing_network ? 0 : 1
  cidr_block                 = var.db_transit_subnet_cidr_block
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.db[count.index].id
  display_name               = var.db_transit_subnet_display_name
  dns_label                  = var.db_transit_subnet_dns_label
  prohibit_public_ip_on_vnic = true
}

# ------ Update Default Security List to All All  Rules
resource "oci_core_security_list" "allow_all_security" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_id : oci_core_vcn.hub.0.id
  display_name   = "AllowAll"
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
