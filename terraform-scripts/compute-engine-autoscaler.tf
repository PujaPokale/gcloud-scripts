provider "google" {
  project     = "my-project-id"
  region      = "us-west1"
}

resource "google_compute_autoscaler" "my-autoscaler" {

  name   = "my-autoscaler"
  zone   = "us-west1-a"
  target = google_compute_instance_group_manager.my-instance-grp-manager.id

  autoscaling_policy {
    max_replicas    = 6
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

resource "google_compute_instance_template" "my-instance-template" {

  name           = "my-instance-template"
  machine_type   = "e2-medium"
  can_ip_forward = false

  disk {
    source_image = data.google_compute_image.my-image.id
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_instance_group_manager" "my-instance-grp-manager" {

  name = "my-instance-grp-manager"
  zone = "us-west1-a"

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
