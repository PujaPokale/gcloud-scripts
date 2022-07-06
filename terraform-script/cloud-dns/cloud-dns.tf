resource "google_dns_managed_zone" "private-forwarding-zone" {
  name        = "private-forwarding-zone"
  dns_name    = "private-forwarding.mydomain.com."
  description = "Example for private DNS zone"
  labels = {
    cl-tag = "dns-tag"
  }


  private_visibility_config {
    networks {
      network_url = google_compute_network.my-vpc-network-1.id
    }
    networks {
      network_url = google_compute_network.my-vpc-network-2.id
    }
  }

  forwarding_config {
    target_name_servers {
      ipv4_address = "172.16.1.16"
    }
    target_name_servers {
      ipv4_address = "172.16.1.28"
    }
  }
}

resource "google_dns_managed_zone" "private-zone" {
  name        = "private-zone"
  dns_name    = "private.myexample.com."
  description = "Example for the private DNS zone"

 
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.my-vpc-network-1.id
    }
    networks {
      network_url = google_compute_network.my-vpc-network-2.id
    }
  }
}

resource "google_dns_record_set" "a-type" {
  name = google_dns_managed_zone.private-zone.dns_name
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.private-zone.name

  rrdatas = [google_compute_instance.my-instance-1.network_interface.access_config.nat_ip]
}

resource "google_dns_record_set" "cname-type" {
  name         = google_dns_managed_zone.private-zone.dns_name
  managed_zone = google_dns_managed_zone.private-zone.name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["alterate-name.mydomain.com."]
}

resource "google_dns_record_set" "geo-location-routing" {
  name         = google_dns_managed_zone.private-zone.dns_name
  managed_zone = google_dns_managed_zone.private-zone.name
  type         = "A"
  ttl          = 300

  routing_policy {

    geo {
      location = "us-central1"
      rrdatas  =  [google_compute_instance.my-instance-1.network_interface.access_config.nat_ip]
    }
    geo {
      location = "asia-east1"
      rrdatas  =  [google_compute_instance.my-instance-2.network_interface.access_config.nat_ip]
    }
  }
}


resource "google_compute_instance" "my-instance-1" {
  name         = "my-instance-1"
  machine_type = "e2-medium"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.my-vpc-network-1.name
    access_config {
    }
  }
}

resource "google_compute_instance" "my-instance-2" {
  name         = "my-instance-2"
  machine_type = "e2-medium"
  zone         = "asia-east1"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.my-vpc-network-2.name
    access_config {
    }
  }
}


resource "google_compute_network" "my-vpc-network-1" {
  name                    = "my-vpc-network-1"
  auto_create_subnetworks = true
  routing_mode = "GLOBAL"
}

resource "google_compute_network" "my-vpc-network-2" {
  name                    = "my-vpc-network-2"
  auto_create_subnetworks = true
  routing_mode = "GLOBAL"
}
