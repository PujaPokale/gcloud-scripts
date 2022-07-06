
variable "project" {
  default = "my-project"
  type        = string
}

variable "name" {

 default = "http-load-balancer"
  type        = string
}

variable "backends" {
  description = "Map backend indices to list of backend maps."
  type = map(object({
    protocol  = string
    port      = number
    port_name = string

    description             = string
    timeout_sec                     = number
    connection_draining_timeout_sec = number

    health_check = object({
      check_interval_sec  = number
      timeout_sec         = number
      healthy_threshold   = number
      unhealthy_threshold = number
      request_path        = string
      port                = number
    })

    groups = list(object({
      group = string

      balancing_mode               = string
      capacity_scaler              = number
      description                  = string
      max_connections              = number
      max_connections_per_instance = number
      max_utilization              = number
    }))
  }))

  default = {
    "http_backend" = {
      connection_draining_timeout_sec = 5
      description = "http backend service"
      groups = [ {
        group = "${google_compute_instance_group_manager.my-instance-grp-manager-1.id}"
        balancing_mode = "UTILIZATION"
        capacity_scaler = 0.5
        description = "mig1"
        max_connections = 3
        max_connections_per_instance = 3
        max_utilization = 1
      },
      {
        group = "${google_compute_instance_group_manager.my-instance-grp-manager-1.id}"
        balancing_mode = "UTILIZATION"
        capacity_scaler = 0.6
        description = "mig2"
        max_connections = 5
        max_connections_per_instance = 5
        max_utilization = 1
      }
       ]
      health_check = {
        check_interval_sec = 5
        healthy_threshold = 2
        port = 80
        request_path = "/my-request-path"
        timeout_sec = 3
        unhealthy_threshold = 1
      }
      port = 80
      port_name = "http"
      protocol = "HTTP"
      timeout_sec = 30
    },
      "https_backend" = {
      connection_draining_timeout_sec = 5
      description = "https backebd service"
      groups = [ {
        group = "${google_compute_instance_group_manager.my-instance-grp-manager-1.id}"
        balancing_mode = "UTILIZATION"
        capacity_scaler = 0.6
        description = "mig1"
        max_connections = 3
        max_connections_per_instance = 3
        max_utilization = 1
      },
      {
        group = "${google_compute_instance_group_manager.my-instance-grp-manager-1.id}"
        balancing_mode = "UTILIZATION"
        capacity_scaler = 0.6
        description = "mig2"
        max_connections = 5
        max_connections_per_instance = 5
        max_utilization = 1
      }
       ]
      health_check = {
        check_interval_sec = 5
        healthy_threshold = 2
        port = 443
        request_path = "/my-path"
        timeout_sec = 3
        unhealthy_threshold = 1
      }

      port = 443
      port_name = "https"
      protocol = "HTTPS"
      timeout_sec = 30
    }
  }

}

variable "labels" {
  description = "The labels to attach to resources created by this module"
  type        = map(string)
  default     = {
    load = "bal"
  }
}
