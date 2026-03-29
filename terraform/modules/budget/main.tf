resource "oci_budget_budget" "this" {
  amount                 = var.budget_amount
  compartment_id         = var.compartment_id
  display_name           = "${var.name_prefix}-budget"
  processing_period_type = "MONTH"
  reset_period           = "MONTHLY"
  target_type            = "COMPARTMENT"
  targets                = var.target_compartment_ids
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }
}

resource "oci_budget_alert_rule" "this" {
  budget_id      = oci_budget_budget.this.id
  display_name   = "${var.name_prefix}-budget-alert"
  threshold      = var.alert_threshold
  threshold_type = "ABSOLUTE"
  type           = "ACTUAL"
  message        = "You have exceeded ${var.alert_threshold} threshold on your ${var.budget_amount} budget!"
  recipients     = join(",", [for email in var.alert_email_addresses : email])
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }
}
