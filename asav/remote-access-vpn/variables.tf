#Variables declared in this file must be declared in the marketplace.yaml

############################
#  Hidden Variable Group   #
############################
variable "tenancy_ocid" {
}

variable "region" {
}


############################
# Compartment Variables    #
############################

variable "compute_compartment_ocid" {
  description = "Compartment where Compute and Marketplace subscription resources will be created"
}

variable "network_compartment_ocid" {
  description = "Compartment where Network resources will be created"
}

variable "subnet_network_compartment_ocid" {
  description = "Compartment where Network resources will be created"
}

############################
# Object Storage Variables #
############################

variable "bucket_name" {
  description = "name of bucket used to upload files to ASAv"
  default     = "POC_Files"
}

variable "bucket_request_expiration" {
  description = "Expiration date of Bucket Pre-Authenticated Request"
  default     = "2022-07-05T23:59:53+00:00" 
}
############################
#  Marketplace Image      #
############################

variable "mp_subscription_enabled" {
  description = "Subscribe to Marketplace listing?"
  type        = bool
  default     = true
}

variable "mp_listing_id" {
  default     = "ocid1.appcataloglisting.oc1..aaaaaaaax34vvyhbw4vomqapj3yczicrkeq72gd5m4z4z7qatzv4hgwejsoa"
  description = "Marketplace Listing OCID"
}

variable "mp_listing_resource_id" {
  default     = "ocid1.image.oc1..aaaaaaaacy7uid4psrvto7l742kzv3uw7whpycf7irqt2sewnbu7mpgckvpa"
  description = "Marketplace Listing Image OCID"
}

variable "mp_listing_resource_version" {
  default     = "9.16.1"
  description = "Marketplace Listing Package/Resource Version"
}

############################
#  Compute Configuration   #
############################

variable "vm_display_name" {
  description = "Instance Name"
  default     = "ASAv-Terraform-VPN"
}

variable "vpn_url" {
  description = "URL to Access VPN"
  default     = "oci-vpn.security-hq.io" 
}

variable "vm_compute_shape" {
  description = "Compute Shape"
  default     = "VM.Standard2.4" //4 cores
}

variable "spoke_vm_compute_shape" {
  description = "Compute Shape"
  default     = "VM.Standard2.2" //2 cores
}

variable "vm_flex_shape_ocpus" {
  description = "Flex Shape OCPUs"
  default     = 4
}

variable "spoke_vm_flex_shape_ocpus" {
  description = "Spoke VMs Flex Shape OCPUs"
  default     = 4
}

variable "availability_domain_name" {
  default     = ""
  description = "Availability Domain"
}

variable "availability_domain_number" {
  default     = 1
  description = "OCI Availability Domains: 1,2,3  (subject to region availability)"
}

variable "ssh_public_key" {
  default = ""
  description = "SSH Public Key String"
}

variable "instance_launch_options_network_type" {
  description = "NIC Attachment Type"
  default     = "PARAVIRTUALIZED"
}

############################
#  VM IP Addressing        #
############################

variable "vm_management_ip" {
  description = "Static IPs used by ASAv Management Interfaces"
  type        = list(string)
  default     = [
    "10.254.0.11", 
    "10.254.0.12",
    ]
}

variable "vm_outside_ip" {
  description = "Static IPs used by ASAv Outside Interfaces"
  type        = list(string)
  default     = [
    "10.1.254.11",
    "10.1.254.12",
  ]
}

variable "vm_inside_ip" {
  description = "Static IPs used by ASAv Inside Interfaces"
  type        = list(string)
   default     = [
     "10.2.254.11",
     "10.2.254.12",   
  ]
}

variable "vpn_pool_cidr_block" {
  description = "The CIDR Block from which Individual VPN IP Pools are Defined"
  default     = "172.16.0.0/16"
}

variable "vpn_pools" {
  description = "Individual VPN Pool Subnets used by ASAv"
  type        = list(string)
  default     = [
    "172.16.1.0/24",
    "172.16.2.0/24"
  ]
}

variable "ise_ip" {
  default = "10.2.254.100"
}

############################
#  Network Configuration   #
############################

variable "network_strategy" {
  default = "Use Existing VCN"
}

variable "subnet_network_strategy" {
  default = "Create New Subnets"
}

variable "subnet_span" {
  description = "Choose between regional and AD specific subnets"
  default     = "Regional Subnet"
}

variable "internet_proxy_ip"  {
  description = "IP Used as Internet Proxy"
  default     = ""
}

# VCN Configuration

variable "existing_vcn_display_name" {
  description = "Display name of Existing VCN used for Deployment"
  default = "Terraform-Existing-VCN"
}

variable "vcn_management_id" {
  default = ""
}

variable "vcn_management_display_name" {
  description = "VCN Name"
  default     = "management-terraform"
}

variable "vcn_management_cidr_block" {
  description = "VCN CIDR"
  default     = "10.254.0.0/24"
}

variable "vcn_management_dns_label" {
  description = "VCN DNS Label"
  default     = "asav"
}

variable "vcn_outside_id" {
  default = ""
}

variable "vcn_outside_display_name" {
  description = "VCN Name"
  default     = "outside-terraform"
}

variable "vcn_outside_cidr_block" {
  description = "VCN CIDR"
  default     = "10.1.254.0/24"
}

variable "vcn_outside_dns_label" {
  description = "VCN DNS Label"
default     = "asav"     
}

variable "vcn_inside_id" {
  default = ""
}

variable "vcn_inside_display_name" {
  description = "VCN Name"
  default     = "inside-terraform"
}

variable "vcn_inside_cidr_block" {
  description = "VCN CIDR"
  default     = "10.2.254.0/24"
}

variable "vcn_inside_dns_label" {
  description = "VCN DNS Label"
  default     = "asav"
}

# Subnet Configuration

variable "management_subnet_id" {
  default = ""
}

variable "management_subnet_display_name" {
  description = "Management Subnet Name"
  default     = "management-subnet"
}

variable "management_subnet_cidr_block" {
  description = "Management Subnet CIDR"
  default     = "10.254.0.0/24"
}

variable "management_subnet_dns_label" {
  description = "Management Subnet DNS Label"
  default     = "management"
}

variable "inside_subnet_id" {
  default = ""
}

variable "inside_subnet_display_name" {
  description = "Trust Subnet Name"
  default     = "inside-subnet"
}

variable "inside_subnet_cidr_block" {
  description = "Trust Subnet CIDR"
  default     = "10.2.254.0/24"
}

variable "inside_subnet_dns_label" {
  description = "Trust Subnet DNS Label"
  default     = "inside"
}

variable "outside_subnet_id" {
  default = ""
}

variable "outside_subnet_display_name" {
  description = "Cisco Outside Subnet Name"
  default     = "outside-subnet"
}

variable "outside_subnet_cidr_block" {
  description = "Cisco Outside Subnet CIDR"
  default     = "10.1.254.0/24"
}

variable "outside_subnet_dns_label" {
  description = "Outside Subnet DNS Label"
  default     = "outside"
}

######################
#    Enum Values     #   
######################
variable "network_strategy_enum" {
  type = map
  default = {
    CREATE_NEW_VCN_SUBNET   = "Create New VCN and Subnet"
    USE_EXISTING_VCN_SUBNET = "Use Existing VCN and Subnet"
  }
}

variable "subnet_network_strategy_enum" {
  type = map
  default = {
    CREATE_NEW_SUBNETS   = "Create New Subnets"
    USE_EXISTING_SUBNETS = "Use Existing Subnets"
  }
}

variable "subnet_type_enum" {
  type = map
  default = {
    transit_subnet    = "Private Subnet"
    MANAGEMENT_SUBENT = "Public Subnet"
  }
}
