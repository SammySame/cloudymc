module "vcn" {
  source         = "./modules/vcn"
  name_prefix    = var.identifier
  vcn_cidr       = var.vcn_cidr
  compartment_id = oci_identity_compartment.this.id
}

module "subnet" {
  source            = "./modules/subnet"
  name_prefix       = var.identifier
  ingress_ports     = var.ingress_ports
  vcn_cidr          = var.vcn_cidr
  subnet_netnum     = var.subnet_netnum
  vcn_id            = module.vcn.vcn_id
  network_entity_id = module.vcn.internet_gateway_id
  compartment_id    = oci_identity_compartment.this.id
}

module "instance" {
  source              = "./modules/instance"
  name_prefix         = var.identifier
  shape               = var.instance_shape
  image               = var.instance_image
  ocpus               = var.instance_ocpus
  ram                 = var.instance_ram
  volume_size         = var.instance_volume_size
  public_ssh_key_path = var.public_ssh_key_path
  subnet_id           = module.subnet.subnet_id
  subnet_cidr         = module.subnet.subnet_cidr
  compartment_id      = oci_identity_compartment.this.id
  availability_domain = data.oci_identity_availability_domain.this.name
}

module "budget" {
  // Create only if the oci_free_tier_only variable is set to true
  count                  = var.oci_free_tier_only ? 1 : 0
  source                 = "./modules/budget"
  name_prefix            = var.identifier
  budget_amount          = 1
  alert_threshold        = 0.01
  alert_email_addresses  = var.alert_email_addresses
  target_compartment_ids = [oci_identity_compartment.this.id]
  // Required to reside in the root compartment
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_compartment" "this" {
  compartment_id = var.tenancy_ocid
  description    = var.compartment_description
  name           = var.compartment_name
}
