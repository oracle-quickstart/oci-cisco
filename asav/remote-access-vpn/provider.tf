terraform {
  required_version = ">= 0.12.0"
}

# ------ Assign OCI Provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ------ Assign Explicit Home Region OCI Provider
provider "oci" {
  alias            = "home_region"
  region           = lookup(data.oci_identity_regions.home-region.regions[0], "name")
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

# Variables required by the OCI Provider only when running Terraform CLI with standard user based Authentication
variable "user_ocid" {
}

variable "fingerprint" {
}

variable "private_key_path" {
}
