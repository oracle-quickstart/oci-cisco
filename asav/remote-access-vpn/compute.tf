# ------ Create Cisco VMs  
resource "oci_core_instance" "asa-vms" {
  depends_on = [oci_core_app_catalog_subscription.mp_image_subscription, oci_core_subnet.management_subnet]
  count      = 2

  availability_domain = (var.availability_domain_name != "" ? var.availability_domain_name : data.oci_identity_availability_domains.ads.availability_domains[count.index + 1].name)
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
    subnet_id              = local.use_existing_subnet ? var.management_subnet_id : oci_core_subnet.management_subnet.id
    display_name           = "Management"
    assign_public_ip       = false
    private_ip             = "${var.vm_management_ip[count.index]}"
    skip_source_dest_check = true
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
    user_data = base64encode(templatefile("user-data/cloud-init-asav.tpl", {
      hostname                        = "${var.vm_display_name}-${count.index + 1}"
      vpn_pool_min                    = "${cidrhost(var.vpn_pools[count.index], 2)}"
      vpn_pool_max                    = "${cidrhost(var.vpn_pools[count.index], -2)}"
      vpn_mask                        = "${cidrnetmask(var.vpn_pools[count.index])}"      
      management_ip                   = "${var.vm_management_ip[count.index]} ${cidrnetmask(data.oci_core_subnet.management_subnet.cidr_block)}"
      outside_ip                      = "${var.vm_outside_ip[count.index]} ${cidrnetmask(data.oci_core_subnet.outside_subnet.cidr_block)}"
      inside_ip                       = "${var.vm_inside_ip[count.index]} ${cidrnetmask(data.oci_core_subnet.outside_subnet.cidr_block)}"
      management_subnet               = "${data.oci_core_subnet.management_subnet.virtual_router_ip}"
      outside_subnet                  = "${data.oci_core_subnet.outside_subnet.virtual_router_ip}"
      inside_subnet                   = "${data.oci_core_subnet.inside_subnet.virtual_router_ip}"
      vpn_pool_subnet                 = "${cidrhost(var.vpn_pools[count.index], 0)}"
      ise_ip                          = "${var.ise_ip}"
      vpn_url                         = "${var.vpn_url}"
      preauthenticated_bucket_request = "test"
    }))
  }
}

resource "oci_core_vnic_attachment" "outside_vnic_attachment" {
  display_name = "OutsideAttachment"
  count = 2
  create_vnic_details {
    subnet_id              = local.use_existing_subnet ? var.outside_subnet_id : oci_core_subnet.outside_subnet[0].id
    assign_public_ip       = false 
    private_ip             = "${var.vm_outside_ip[count.index]}"
    skip_source_dest_check = true
    display_name           = "Outside"
  }
  instance_id = oci_core_instance.asa-vms[count.index].id
  depends_on = [
    oci_core_instance.asa-vms,
  ]
}

resource "oci_core_vnic_attachment" "inside_vnic_attachment" {
  display_name = "InsideAttachment"
  count        = 2
  create_vnic_details {
    subnet_id              = local.use_existing_subnet ? var.inside_subnet_id : oci_core_subnet.inside_subnet[0].id
    assign_public_ip       = false
    private_ip             = "${var.vm_inside_ip[count.index]}"
    skip_source_dest_check = true
    display_name           = "Inside"
  }
  instance_id = oci_core_instance.asa-vms[count.index].id
  depends_on = [
    oci_core_instance.asa-vms,
    oci_core_vnic_attachment.outside_vnic_attachment
  ]
}

# Assign a reserved public IP to the private IP
resource "oci_core_public_ip" "ReservedPublicIPAssigned" {
  count          = 2
  compartment_id = var.compute_compartment_ocid
  display_name   = "TFReservedPublicIPAssigned"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.asav_management_private_ips[count.index].private_ips.*.id[0]

  depends_on = [
    oci_core_vnic_attachment.inside_vnic_attachment
  ]
}

