# ------ Create Firewall Manager
resource "oci_core_instance" "firewall-manager" {
  depends_on = [oci_core_app_catalog_subscription.mp_fmc_image_subscription]
  count      = 1

  availability_domain = ( var.availability_domain_name != "" ? var.availability_domain_name : ( length(data.oci_identity_availability_domains.ads.availability_domains) == 1 ? data.oci_identity_availability_domains.ads.availability_domains[0].name : data.oci_identity_availability_domains.ads.availability_domains[count.index].name))
  compartment_id      = var.network_compartment
  display_name        = "${var.vm_fmc_display_name}"
  shape               = var.vm_compute_shape

  dynamic "shape_config" {
    for_each = local.is_flex_fmc_shape
    content {
      ocpus = shape_config.value
    }
  }

  create_vnic_details {
    subnet_id        = data.oci_core_subnets.dmz_vcn_subnets_mgmt.subnets.0.id
    display_name     = var.vm_display_name
    assign_public_ip = true
    # nsg_ids                = [oci_core_network_security_group.nsg.id]
    skip_source_dest_check = "true"
  }

  source_details {
    source_type = "image"
    source_id   = local.listing_fmc_resource_id
  }

  launch_options {
    network_type = var.instance_launch_options_network_type
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

}

# ------ Create Firewall VMs  
resource "oci_core_instance" "firewall-vms" {
  depends_on = [oci_core_app_catalog_subscription.mp_image_subscription, oci_core_instance.firewall-manager]
  count      = 2

  availability_domain = ( var.availability_domain_name != "" ? var.availability_domain_name : ( length(data.oci_identity_availability_domains.ads.availability_domains) == 1 ? data.oci_identity_availability_domains.ads.availability_domains[0].name : data.oci_identity_availability_domains.ads.availability_domains[count.index].name))
  compartment_id      = var.network_compartment
  display_name        = "${var.vm_display_name}-${count.index + 1}"
  shape               = var.vm_compute_shape

  dynamic "shape_config" {
    for_each = local.is_flex_shape
    content {
      ocpus = shape_config.value
    }
  }

  create_vnic_details {
    subnet_id        = data.oci_core_subnets.dmz_vcn_subnets_mgmt.subnets.0.id
    display_name     = var.vm_display_name
    assign_public_ip = true
    # nsg_ids                = [oci_core_network_security_group.nsg.id]
    skip_source_dest_check = "true"
  }

  source_details {
    source_type = "image"
    source_id   = local.listing_resource_id
  }

  launch_options {
    network_type = var.instance_launch_options_network_type
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("user-data/cloud-init.tpl", {
      hostname    = "${var.vm_display_name}-${count.index + 1}"
      fmc_ip      = oci_core_instance.firewall-manager.0.public_ip
      fmc_reg_key = "cisco123reg${count.index + 1}"
      fmc_nat_id  = "cisco123nat${count.index + 1}"
    }))
  }
}

# ------ Attach Diagnostic VNICs
resource "oci_core_vnic_attachment" "diagnostic_vnic_attachment" {
  count = 2
  create_vnic_details {
    subnet_id              = data.oci_core_subnets.dmz_vcn_subnets_ha.subnets.0.id
    assign_public_ip       = "false"
    skip_source_dest_check = "true"
    # nsg_ids                = [oci_core_network_security_group.nsg.id]
    display_name = "Diagnostic"
  }
  instance_id = oci_core_instance.firewall-vms[count.index].id
  depends_on = [
    oci_core_instance.firewall-vms
  ]
}

# ------ Attach Indoor VNICs
resource "oci_core_vnic_attachment" "indoor_vnic_attachment" {
  count = 2
  create_vnic_details {
    subnet_id              = data.oci_core_subnets.dmz_vcn_subnets_indoor.subnets.0.id
    assign_public_ip       = "false"
    skip_source_dest_check = "true"
    # nsg_ids                = [oci_core_network_security_group.nsg.id]
    display_name = "Inside"
  }
  instance_id = oci_core_instance.firewall-vms[count.index].id
  depends_on = [
    oci_core_instance.firewall-vms,
    oci_core_vnic_attachment.diagnostic_vnic_attachment
  ]
}

# ------ Attach Outdoor VNICs
resource "oci_core_vnic_attachment" "outdoor_vnic_attachment" {
  count = 2
  create_vnic_details {
    subnet_id              = data.oci_core_subnets.dmz_vcn_subnets_outdoor.subnets.0.id
    assign_public_ip       = "true"
    skip_source_dest_check = "true"
    # nsg_ids                = [oci_core_network_security_group.nsg.id]
    display_name = "Outside"
  }
  instance_id = oci_core_instance.firewall-vms[count.index].id
  depends_on = [
    oci_core_vnic_attachment.indoor_vnic_attachment
  ]
}
