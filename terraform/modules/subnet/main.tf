resource "oci_core_subnet" "this" {
  compartment_id    = var.compartment_id
  security_list_ids = [oci_core_security_list.this.id]
  route_table_id    = oci_core_route_table.this.id
  vcn_id            = var.vcn_id
  display_name      = "${var.name_prefix}-subnet"
  cidr_block        = cidrsubnet(var.vcn_cidr, 8, var.subnet_netnum)
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }
}

resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.name_prefix}-route-table"
  route_rules {
    network_entity_id = var.network_entity_id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }
}

resource "oci_core_security_list" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.name_prefix}-security-list"
  dynamic "ingress_security_rules" {
    for_each = var.ingress_ports
    content {
      description = "User defined rule"
      stateless   = false
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      protocol    = local.protocol_map[lower(ingress_security_rules.value.protocol)]
      dynamic "tcp_options" {
        for_each = (lower(ingress_security_rules.value.protocol) == "tcp"
        ? [ingress_security_rules.value] : [])
        content {
          min = tcp_options.value.number
          max = tcp_options.value.number
        }
      }
      dynamic "udp_options" {
        for_each = (lower(ingress_security_rules.value.protocol) == "udp"
        ? [ingress_security_rules.value] : [])
        content {
          min = udp_options.value.number
          max = udp_options.value.number
        }
      }
    }
  }
  ingress_security_rules {
    description = "Default"
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    description = "Default"
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    description = "Default"
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    icmp_options {
      type = 3
    }
  }
  egress_security_rules {
    description      = "WWW traffic (HTTP)"
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      min = 80
      max = 80
    }
  }
  egress_security_rules {
    description      = "WWW traffic (HTTPS)"
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      min = 443
      max = 443
    }
  }
  egress_security_rules {
    description      = "Domain Name System traffic (UDP)"
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "17"
    udp_options {
      min = 53
      max = 53
    }
  }
  egress_security_rules {
    description      = "Domain Name System traffic (TCP)"
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      min = 53
      max = 53
    }
  }
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedBy"],
      defined_tags["Oracle-Tags.CreatedOn"],
    ]
  }
}
