# ------ Get Network Compartment Name for Policies
data "oci_identity_compartment" "network_compartment" {
  id = var.network_compartment_ocid
}

# ------ Get list of availability domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# ------ Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID" {
  compartment_id = var.compute_compartment_ocid
  shape = var.spoke_vm_compute_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

# ------ Get the Oracle Tenancy ID
data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_core_vcns" "existing_vcn_utilized" {
    compartment_id = var.network_compartment_ocid
    display_name   = var.existing_vcn_display_name
}

# ------ Get the Tenancy ID and AD Number
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.availability_domain_number
}

# ------ Get the Tenancy ID and ADs
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# ------ Get the Faulte Domain within AD 
data "oci_identity_fault_domains" "fds" {
  availability_domain = "${data.oci_identity_availability_domain.ad.name}"
  compartment_id      = var.compute_compartment_ocid

  depends_on = [
    data.oci_identity_availability_domain.ad,
  ]
}

# ------- Retrieve Namespace for Bucket
data "oci_objectstorage_namespace" "storage_namespace" {
  compartment_id = var.tenancy_ocid
}

# ------- Retrieve Outside IGWs
data "oci_core_internet_gateways" "outside-internet-gws" {
  compartment_id  = var.network_compartment_ocid
  vcn_id          = var.vcn_outside_id
}

# ------- Retrieve the Outside Private IP OCID from ASAv
data "oci_core_private_ips" "asav_outside_private_ips" {
  count      = 2
  vnic_id    = oci_core_vnic_attachment.outside_vnic_attachment[count.index].vnic_id

    depends_on = [
    oci_core_vnic_attachment.outside_vnic_attachment,
  ]
}

# ------- Retrieve the Inside Private IP OCID from ASAv
data "oci_core_private_ips" "asav_inside_private_ips" {
  count      = 2
  vnic_id    = oci_core_vnic_attachment.inside_vnic_attachment[count.index].vnic_id

  depends_on = [
    oci_core_vnic_attachment.inside_vnic_attachment,
  ]
}

# ------- Retrieve the Management Private IP OCID from ASAv
data "oci_core_vnic_attachments" "asav_vnic_attachments" {
  count          = 2
  compartment_id = var.compute_compartment_ocid
  instance_id    = oci_core_instance.asa-vms[count.index].id

  depends_on = [
    oci_core_instance.asa-vms,
  ]
}
data "oci_core_private_ips" "asav_management_private_ips" {
  count      = 2
  vnic_id    = data.oci_core_vnic_attachments.asav_vnic_attachments[count.index].vnic_attachments[0].vnic_id

  depends_on = [
    oci_core_instance.asa-vms,
  ]
}
# -------- Get info on Management Subnet
data "oci_core_subnet" "management_subnet" {
  subnet_id = local.use_existing_subnet ? var.management_subnet_id : oci_core_subnet.management_subnet.id

  depends_on = [
    oci_core_subnet.management_subnet
  ]
}

# -------- Get info on Outside Subnet
data "oci_core_subnet" "outside_subnet" {
  subnet_id = local.use_existing_subnet ? var.outside_subnet_id : oci_core_subnet.outside_subnet[0].id

  depends_on = [
    oci_core_subnet.outside_subnet
  ]
}

# -------- Get info on Inside Subnet
data "oci_core_subnet" "inside_subnet" {
  subnet_id = local.use_existing_subnet ? var.inside_subnet_id : oci_core_subnet.inside_subnet[0].id
  depends_on = [
    oci_core_subnet.inside_subnet
  ]
}


# ------ Get the Allow All Security Lists for Subnets in Firewall VCN
data "oci_core_security_lists" "outside_security_list" {
  compartment_id = var.compute_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_outside_id : oci_core_vcn.outside.0.id
  filter {
    name   = "display_name"
    values = ["Outside-Security-List-Terraform"]
  }
  depends_on = [
    oci_core_security_list.outside_security_list,
  ]
}

# ------ Get the Allow All Security Lists for Subnets in Firewall VCN
data "oci_core_security_lists" "inside_security_list" {
  compartment_id = var.compute_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_inside_id : oci_core_vcn.inside.0.id
  filter {
    name   = "display_name"
    values = ["Inside-Security-List-Terraform"]
  }
  depends_on = [
    oci_core_security_list.outside_security_list,
  ]
}

# ------ Get the Allow All Security Lists for Subnets in Firewall VCN
data "oci_core_security_lists" "management_security_list" {
  compartment_id = var.compute_compartment_ocid
  vcn_id         = local.use_existing_network ? var.vcn_management_id : oci_core_vcn.management.0.id
  filter {
    name   = "display_name"
    values = ["Management-Security-List-Terraform"]
  }
  depends_on = [
    oci_core_security_list.outside_security_list,
  ]
}