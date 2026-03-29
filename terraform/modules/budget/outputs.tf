output "budget_id" {
  description = "Budget OCID."
  value       = oci_budget_budget.this.id
}

output "budget_alert_id" {
  description = "Budget alert OCID."
  value       = oci_budget_alert_rule.this.id
}
