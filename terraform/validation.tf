locals {
  // Every instance that is unmanaged by this Terraform state.
  unmanaged_instances = {
    for inst in local.all_instances :
    inst.display_name => inst if inst.display_name != module.instance.instance_name
  }
  // Every volume and boot volume that is unmanaged by this Terraform state.
  unmanaged_volumes = merge({
    for vol in local.all_volumes :
    vol.display_name => vol
    }, {
    for vol in local.all_boot_volumes :
    vol.display_name =>
    vol if vol.display_name != module.instance.boot_volume_name && vol.state != "TERMINATED"
  })
}

resource "terraform_data" "free_tier_validate" {
  // Validate if the oci_free_tier_only is set to true.
  count = var.oci_free_tier_only ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.instance_shape == "VM.Standard.A1.Flex"
      error_message = "Non-free or/and suboptimal VM shape chosen. Please use \"VM.Standard.A1.Flex\"."
    }
    precondition {
      condition     = length(local.unmanaged_instances) + 1 < 4
      error_message = <<-EOT
      Free tier exceeded: The total amount of instances is greater than 4.
      %{if length(local.unmanaged_instances) > 0}
      Note that ${length(local.unmanaged_instances)} other running instances count towards the limit in your tenancy.
      %{endif}
      EOT
    }
    precondition {
      condition = sum(concat(
        [var.instance_ocpus],
        [for inst in local.unmanaged_instances : one(inst.shape_config).ocpus])
      ) <= 4
      error_message = <<-EOT
      Free tier exceeded: The total amount of used ocpus is greater than 4.
      %{if length(local.unmanaged_instances) > 0}
      Note that ${length(local.unmanaged_instances)} other running instances count towards the limit in your tenancy.
      %{endif}
      EOT
    }
    precondition {
      condition = sum(concat(
        [var.instance_ram],
        [for inst in local.unmanaged_instances : one(inst.shape_config).memory_in_gbs])
      ) <= 24
      error_message = <<-EOT
      Free tier exceeded: The total amount of used ram is greater than 24GB.
      %{if length(local.unmanaged_instances) > 0}
      Note that ${length(local.unmanaged_instances)} other running instances count towards the limit in your tenancy.
      %{endif}
      EOT
    }
    precondition {
      condition = sum(concat(
        [var.instance_volume_size],
        [for vol in local.unmanaged_volumes : vol.size_in_gbs])
      ) <= 200
      error_message = <<-EOT
      Free tier exceeded: The total amount of used storage is greater than 200GB.
      %{if length(local.unmanaged_volumes) > 0}
      Note that ${length(local.unmanaged_volumes)} other volumes count towards the limit in your tenancy.
      %{endif}
      EOT
    }
  }
}
