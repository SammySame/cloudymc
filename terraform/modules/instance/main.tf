locals {
  ssh_keys = [for path in var.public_ssh_key_paths : file(path)]
}

resource "oci_core_instance" "this" {
  display_name         = var.name_prefix
  compartment_id       = var.compartment_id
  availability_domain  = var.availability_domain
  preserve_boot_volume = var.preserve_boot_volume
  shape                = var.shape
  shape_config {
    memory_in_gbs = var.ram
    ocpus         = var.ocpus
  }
  source_details {
    source_type             = "image"
    source_id               = var.image
    boot_volume_size_in_gbs = var.volume_size
    boot_volume_vpus_per_gb = "10"
  }
  create_vnic_details {
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    display_name              = "${var.name_prefix}-vnic"
    subnet_id                 = var.subnet_id
    subnet_cidr               = var.subnet_cidr
  }
  metadata = {
    "ssh_authorized_keys" = join("\n", [for key in local.ssh_keys : key])
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name          = "Cloud Guard Workload Protection"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute RDMA GPU Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Auto-Configuration"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Authentication"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }
}
