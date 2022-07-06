
provider "google" {
  project  = var.project
}

locals {
  address      = google_compute_global_address.default.address
  url_map             = google_compute_url_map.default.self_link
  health_checked_backends = { for backend_index, backend_value in var.backends : backend_index => backend_value if backend_value["health_check"] != null }
}


# forwarding rule for http
resource "google_compute_global_forwarding_rule" "http" {
  name       = var.name
  target     = google_compute_target_http_proxy.default.self_link
  ip_address = local.address
  port_range = "80"
  labels     = var.labels
}


# IPv4 block
resource "google_compute_global_address" "default" {
  name       = "global-address"
  ip_version = "IPV4"
  labels     = var.labels
}
 

# HTTP proxy for http forwarding
resource "google_compute_target_http_proxy" "default" {
  name    = "default-http-proxy"
  url_map = local.url_map
}


resource "google_compute_url_map" "default" {
  name            = "default-url-map"
  default_service = google_compute_backend_service.default[keys(var.backends)[0]].self_link
}

# backend service
resource "google_compute_backend_service" "default" {
  for_each = var.backends
  name    = "${var.name}-backend-${each.key}"
  port_name = each.value.port_name
  protocol  = each.value.protocol

  timeout_sec                     = lookup(each.value, "timeout_sec", 30)
  description                     = lookup(each.value, "description", "default")
  connection_draining_timeout_sec = lookup(each.value, "connection_draining_timeout_sec", 10)
  health_checks                   = lookup(each.value, "health_check", null) == null ? null : [google_compute_health_check.default[each.key].self_link]

  dynamic "backend" {
    for_each = toset(each.value["groups"])
    content {
      description = lookup(backend.value, "description")
      group       = lookup(backend.value, "group")

      balancing_mode               = lookup(backend.value, "balancing_mode")
      capacity_scaler              = lookup(backend.value, "capacity_scaler")
      max_connections              = lookup(backend.value, "max_connections")
      max_connections_per_instance = lookup(backend.value, "max_connections_per_instance")
      max_utilization              = lookup(backend.value, "max_utilization")
    }
  }

  depends_on = [
    google_compute_health_check.default
  ]

}

resource "google_compute_health_check" "default" {
  for_each = local.health_checked_backends
  name     = "${var.name}-hc-${each.key}"

  check_interval_sec  = lookup(each.value["health_check"], "check_interval_sec", 5)
  timeout_sec         = lookup(each.value["health_check"], "timeout_sec", 5)
  healthy_threshold   = lookup(each.value["health_check"], "healthy_threshold", 2)
  unhealthy_threshold = lookup(each.value["health_check"], "unhealthy_threshold", 2)

  dynamic "http_health_check" {
    for_each = each.value["protocol"] == "HTTP" ? [
      {
        request_path = lookup(each.value["health_check"], "request_path")
        port         = lookup(each.value["health_check"], "port")
      }
    ] : []

    content {
      request_path = lookup(http_health_check.value, "request_path")
      port         = lookup(http_health_check.value, "port",)
    }
  }

}

resource "google_compute_firewall" "firewall-rule-to-allow-hc" {
  name    = "default-firewall-rule"
  network = google_compute_network.my-vpc-network.id
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  dynamic "allow" {
    for_each = local.health_checked_backends
    content {
      protocol = "tcp"
      ports    = [allow.value["health_check"].port]
    }
  }
}


resource "google_compute_network" "my-vpc-network" {
  name = "my-vpc-network"
  routing_mode = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_instance_template" "my-instance-template" {

  name           = "my-instance-template"
  machine_type   = "e2-medium"
  can_ip_forward = false

  disk {
    source_image = data.google_compute_image.my-image.id
  }

  network_interface {
    network = google_compute_network.my-vpc-network.id
  }
}

resource "google_compute_instance_group_manager" "my-instance-grp-manager-1" {

  name = "my-instance-grp-manager-1"
  zone = "us-west1-a"

  version {
    instance_template  = google_compute_instance_template.my-instance-template.id
    name               = "primary"
  }

  base_instance_name = "my-instance"
}

resource "google_compute_instance_group_manager" "my-instance-grp-manager-2" {

  name = "my-instance-grp-manager"
  zone = "us-central1-a"

  version {
    instance_template  = google_compute_instance_template.my-instance-template.id
    name               = "primary"
  }

  base_instance_name = "my-instance"
}

data "google_compute_image" "my-image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_autoscaler" "my-autoscaler" {

  name   = "my-autoscaler"
  zone   = "us-west1-a"
  target = google_compute_instance_group_manager.my-instance-grp-manager-1.id

  autoscaling_policy {
    max_replicas    = 6
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}
