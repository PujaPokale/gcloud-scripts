
resource "google_compute_firewall" "my-firewall-rule" {
  name    = "my-firewall-rule"
  network = google_compute_network.vpc-network.name
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

}

resource "google_compute_network" "vpc-network" {
  name = "my-vpc-network"
  routing_mode = "GLOBAL"
}


