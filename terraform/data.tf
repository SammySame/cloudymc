locals {
  compartments = {
    for c in data.oci_identity_compartments.this.compartments : c.id => c
  }
  all_instances = flatten([
    for i in data.oci_core_instances.this : i.instances
  ])
  all_volumes = flatten([
    for v in data.oci_core_volumes.this : v.volumes
  ])
  all_boot_volumes = flatten([
    for bv in data.oci_core_boot_volumes.this : bv.boot_volumes
  ])
}

data "oci_identity_availability_domain" "this" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.availability_domain_number
}

data "oci_identity_compartments" "this" {
  compartment_id            = var.tenancy_ocid
  access_level              = "ANY"
  compartment_id_in_subtree = true
  state                     = "ACTIVE"
}

data "oci_core_instances" "this" {
  for_each       = local.compartments
  compartment_id = each.key
  state          = "RUNNING"
}

data "oci_core_volumes" "this" {
  for_each       = local.compartments
  compartment_id = each.key
}

data "oci_core_boot_volumes" "this" {
  for_each       = local.compartments
  compartment_id = each.key
}

data "oci_core_instance" "this" {
  instance_id = module.instance.instance_id
}
