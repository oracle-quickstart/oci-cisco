# ------ Create Management VCN
resource "oci_core_vcn" "management" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.vcn_management_cidr_block
  dns_label      = var.vcn_management_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.vcn_management_display_name
}

# ------ Create Management IGW
resource "oci_core_internet_gateway" "igw_management" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  display_name   = "${var.vcn_management_display_name}-igw"
  vcn_id         =  oci_core_vcn.management[count.index].id
  enabled = "true"
}

# ------ Create Outside VCN
resource "oci_core_vcn" "outside" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.vcn_outside_cidr_block
  dns_label      = var.vcn_outside_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.vcn_outside_display_name
}


resource "oci_core_internet_gateway" "igw_outside" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  display_name   = "outside-igw"
  vcn_id         =  oci_core_vcn.outside[count.index].id
  enabled = "true"
}


# ------ Create Inside VCN
resource "oci_core_vcn" "inside" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.vcn_inside_cidr_block
  dns_label      = var.vcn_inside_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.vcn_inside_display_name
}

# ------ Update Management Security List
resource "oci_core_security_list" "management_security_list" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_management_id : oci_core_vcn.management.0.id
  display_name   = "Management-Security-List-Terraform"

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# ------ Update Outside Security List
resource "oci_core_security_list" "outside_security_list" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_outside_id : oci_core_vcn.outside.0.id
  display_name = "Outside-Security-List-Terraform"
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

}

# ------ Update Inside Security List to All All  Rules
resource "oci_core_security_list" "inside_security_list" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_inside_id : oci_core_vcn.inside.0.id
  display_name   = "Inside-Security-List-Terraform"
  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# ------ Routing Table for Outside VCN 
resource "oci_core_route_table" "outside_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_outside_id : oci_core_vcn.outside.0.id
  display_name   = "RouteTable-Outside-Terraform-VPN" #
  route_rules {
     destination       = "0.0.0.0/0"
     destination_type  = "CIDR_BLOCK"
     network_entity_id =  oci_core_internet_gateway.igw_outside[count.index].id
   }
}

# ------ Create Outside Subnet
resource "oci_core_subnet" "outside_subnet" {
  count          = local.use_existing_subnet ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_outside_id : oci_core_vcn.outside[count.index].id
  cidr_block   = var.outside_subnet_cidr_block
  display_name = var.outside_subnet_display_name
  #  route_table_id             = oci_core_route_table.outside_route_table[count.index].id
  dns_label                  = var.outside_subnet_dns_label
  security_list_ids          =   [data.oci_core_security_lists.outside_security_list.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.outside_security_list,
  ]
}

# ------ Routing Table for Managment VCN 
resource "oci_core_route_table" "management_route_table" {
  depends_on     = [oci_core_internet_gateway.igw_management]
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_management_id : oci_core_vcn.management.0.id
  display_name = "RouteTable-Management-Terraform-VPN"

  route_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw_management.0.id
  }
}

# ------ Create Management Subnet
resource "oci_core_subnet" "management_subnet" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_management_id : oci_core_vcn.management.0.id
  cidr_block                 = var.management_subnet_cidr_block
  display_name               = var.management_subnet_display_name
  route_table_id             = oci_core_route_table.management_route_table.id
  dns_label                  = var.management_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.management_security_list.security_lists[0].id]
  prohibit_public_ip_on_vnic = false

  depends_on = [
    oci_core_security_list.management_security_list,
  ]
}

# ------ Create Inside subnet
resource "oci_core_subnet" "inside_subnet" {
  count          = local.use_existing_subnet ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_inside_id : oci_core_vcn.inside[count.index].id
  cidr_block                 = var.inside_subnet_cidr_block
  display_name               = var.inside_subnet_display_name
  dns_label                  = var.inside_subnet_dns_label
  security_list_ids          =   [data.oci_core_security_lists.inside_security_list.security_lists[0].id]
  prohibit_public_ip_on_vnic = "true"

  depends_on = [
    oci_core_security_list.inside_security_list,
  ]
}

# ------ Routing Table for Inside VCN
resource "oci_core_route_table" "inside_route_table" {
  count          = local.use_existing_subnet ? 0 : 1
  depends_on     = [oci_core_vnic_attachment.inside_vnic_attachment]
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_inside_id : oci_core_vcn.inside[count.index].id
  display_name   = "RouteTable-Inside-Terraform-VPN"

  route_rules {
    destination       = var.vpn_pools[0]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.asav_inside_private_ips[0].private_ips[0].id
  }
  route_rules {
    destination       = var.vpn_pools[1]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.asav_inside_private_ips[1].private_ips[0].id
  }
  #  route_rules{
  #    destination       = "0.0.0.0/0"
  #    destination_type  = "CIDR_BLOCK"
  #    network_entity_id = oci_core_nat_gateway.ngw_inside_to_internet[count.index].id
  #  }
}

resource "oci_core_route_table_attachment" "test_route_table_attachment" {
  depends_on = [
    oci_core_route_table.inside_route_table
  ]
  subnet_id      = local.use_existing_subnet ? var.inside_subnet_id : oci_core_subnet.inside_subnet[0].id
  route_table_id = oci_core_route_table.inside_route_table[0].id
}

# ------ Get All Services Data Value 
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
