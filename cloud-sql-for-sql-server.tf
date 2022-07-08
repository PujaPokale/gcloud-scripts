provider "google" {
  region = "us-central1"
  project = "cloud-sql-project"
}

resource "google_sql_database" "my-sql-database" {
  name     = "my-sql-database"
  instance = google_sql_database_instance.sql-server-instance.name
}

resource "google_sql_database_instance" "sql-server-instance" {
  name             = "sql-server-instance-${random_id.db_name_suffix.hex}"
  database_version = "SQLSERVER_2017_STANDARD"
  region = "us-central1"
  root_password = random_password.root_password.result
  deletion_protection = true

  settings {
    tier = "db-e2-medium"
    activation_policy = "ALWAYS"
    availability_type = "REGIONAL"
    disk_autoresize = true
    disk_type = "PD_SSD"

    database_flags {
      name = "sql-123"
      value = "serv-123"
    }

    backup_configuration {
        enabled = true
        start_time = "47:59"
        location = "us-west1"
        transaction_log_retention_days = 1
    }
    
    ip_configuration {

      dynamic "authorized_networks" {

        for_each = google_compute_instance.app-instances
        iterator = app-instances

        content {
          name  = app-instances.value.name
          value = app-instances.value.network_interface.0.access_config.0.nat_ip
        }
      }
    }

    maintenance_window {
        day = 1
        hour = 23
        update_track = "canary"
    }
  }
}

resource "random_password" "root-password" {
  length  = 8
  special = true
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_compute_instance" "app-instances" {
  count        = 4
  name         = "app-instances-${count.index + 1}"
  machine_type = "e2-medium"
  

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = google_compute_network.my-vpc-network.name
    access_config {
    }
  }
}

resource "google_compute_network" "my-vpc-network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = true
  routing_mode = "GLOBAL"
}

