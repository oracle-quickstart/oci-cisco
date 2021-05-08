# ------ Create Cisco VMs  
resource "oci_core_instance" "ftd-vms" {
  depends_on = [oci_core_app_catalog_subscription.mp_image_subscription]
  count      = 2

  availability_domain = (var.availability_domain_name != "" ? var.availability_domain_name : data.oci_identity_availability_domains.ads.availability_domains[count.index].name)
  compartment_id      = var.compute_compartment_ocid
  display_name        = "${var.vm_display_name}-${count.index + 1}"
  shape               = var.vm_compute_shape
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index].name

  dynamic "shape_config" {
    for_each = local.is_flex_shape
    content {
      ocpus = shape_config.value
    }
  }

  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.mangement_subnet_id : oci_core_subnet.mangement_subnet[0].id
    display_name           = var.vm_display_name
    assign_public_ip       = true
    nsg_ids                = [oci_core_network_security_group.nsg.id]
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
  }

}

resource "oci_core_vnic_attachment" "diagnostic_vnic_attachment" {
  count = 2
  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.diagnostic_subnet_id : oci_core_subnet.diagnostic_subnet[0].id
    assign_public_ip       = "false"
    skip_source_dest_check = "true"
    nsg_ids                = [oci_core_network_security_group.nsg.id]
    display_name           = "Diagnostic"
  }
  instance_id = oci_core_instance.ftd-vms[count.index].id
  depends_on = [
    oci_core_instance.ftd-vms
  ]
}


resource "oci_core_vnic_attachment" "inside_vnic_attachment" {
  count = 2
  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.inside_subnet_id : oci_core_subnet.inside_subnet[0].id
    assign_public_ip       = "false"
    skip_source_dest_check = "true"
    nsg_ids                = [oci_core_network_security_group.nsg.id]
    display_name           = "Inside"
  }
  instance_id = oci_core_instance.ftd-vms[count.index].id
  depends_on = [
    oci_core_instance.ftd-vms,
    oci_core_vnic_attachment.diagnostic_vnic_attachment
  ]
}

resource "oci_core_vnic_attachment" "outside_vnic_attachment" {
  count = 2
  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.outside_subnet_id : oci_core_subnet.outside_subnet[0].id
    assign_public_ip       = "true"
    skip_source_dest_check = "true"
    nsg_ids                = [oci_core_network_security_group.nsg.id]
    display_name           = "Outside"
  }
  instance_id = oci_core_instance.ftd-vms[count.index].id
  depends_on = [
    oci_core_vnic_attachment.inside_vnic_attachment
  ]
}


# ------ Create Cisco FMC
resource "oci_core_instance" "cisco-fmc" {
  depends_on = [oci_core_app_catalog_subscription.mp_fmc_image_subscription]
  count      = 1

  availability_domain = (var.availability_domain_name != "" ? var.availability_domain_name : data.oci_identity_availability_domains.ads.availability_domains[count.index].name)
  compartment_id      = var.compute_compartment_ocid
  display_name        = "${var.vm_fmc_display_name}-${count.index + 1}"
  shape               = var.vm_compute_shape
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index].name

  dynamic "shape_config" {
    for_each = local.is_flex_shape
    content {
      ocpus = shape_config.value
    }
  }

  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.mangement_subnet_id : oci_core_subnet.mangement_subnet[0].id
    display_name           = var.vm_display_name
    assign_public_ip       = true
    nsg_ids                = [oci_core_network_security_group.nsg.id]
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

# ------ Create Web Standalone VMs
resource "oci_core_instance" "web-vms" {
  count = 2

  availability_domain = (var.availability_domain_name != "" ? var.availability_domain_name : data.oci_identity_availability_domains.ads.availability_domains[count.index].name)
  compartment_id      = var.compute_compartment_ocid
  display_name        = "${var.vm_display_name_web}-${count.index + 1}"
  shape               = var.spoke_vm_compute_shape
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index].name

  dynamic "shape_config" {
    for_each = local.is_spoke_flex_shape
    content {
      ocpus = shape_config.value
    }
  }

  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.web_transit_subnet_id : oci_core_subnet.web_private-subnet[0].id
    display_name           = var.vm_display_name_web
    assign_public_ip       = false
    nsg_ids                = [oci_core_network_security_group.nsg_web.id]
    skip_source_dest_check = "true"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.InstanceImageOCID.images[1].id
    boot_volume_size_in_gbs = "50"
  }

  launch_options {
    network_type = var.instance_launch_options_network_type
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

}

# ------ Create DB Standalone VMs
resource "oci_core_instance" "db-vms" {
  count = 2

  availability_domain = (var.availability_domain_name != "" ? var.availability_domain_name : data.oci_identity_availability_domains.ads.availability_domains[count.index].name)
  compartment_id      = var.compute_compartment_ocid
  display_name        = "${var.vm_display_name_db}-${count.index + 1}"
  shape               = var.spoke_vm_compute_shape
  fault_domain        = data.oci_identity_fault_domains.fds.fault_domains[count.index].name

  dynamic "shape_config" {
    for_each = local.is_spoke_flex_shape
    content {
      ocpus = shape_config.value
    }
  }

  create_vnic_details {
    subnet_id              = local.use_existing_network ? var.db_transit_subnet_id : oci_core_subnet.db_private-subnet[0].id
    display_name           = var.vm_display_name_db
    assign_public_ip       = false
    nsg_ids                = [oci_core_network_security_group.nsg_db.id]
    skip_source_dest_check = "true"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.InstanceImageOCID.images[1].id
    boot_volume_size_in_gbs = "50"
  }

  launch_options {
    network_type = var.instance_launch_options_network_type
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

}
