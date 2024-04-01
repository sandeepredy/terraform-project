# check if the network is available
/*
data "google_compute_network" "existing_network" {
  name = "my-custom-network"
}
*/
# Create a VPC
resource "google_compute_network" "vpc" {
  #count = length(data.google_compute_network.my-custom-network) == 0 ? 1 : 0
  name                    = "my-custom-network"
  #self_link = google_compute_network.existing_network[count.index].self_link
  auto_create_subnetworks = "false"

  lifecycle {
    ignore_changes = all
  }

}

# Create a Public-Subnet
resource "google_compute_subnetwork" "public-subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.10.1.0/24"
  network       = google_compute_network.vpc.name
  region = "us-central1"

  lifecycle {
    ignore_changes = all
  }
}

## Create a VM in the public-subnet

resource "google_compute_instance" "public-vm" {
  project      = var.project_name
  zone         = "us-central1-a"
  name         = "public-vm"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = "my-custom-network"
    subnetwork = google_compute_subnetwork.public-subnet.name # Replace with a reference or self link to your subnet, in quotes
  }

  lifecycle {
    ignore_changes = all
  }
}

# Create a Private-Subnet
resource "google_compute_subnetwork" "private-subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.10.4.0/24"
  network       = google_compute_network.vpc.name
  region = "us-central1"

  lifecycle {
    ignore_changes = all
  }
}

## Create a VM in the private-subnet

resource "google_compute_instance" "private-vm" {
  project      = var.project_name
  zone         = "us-central1-b"
  name         = "private-vm"
  machine_type = "e2-medium"
  #zone         = "us-central1-b"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = "my-custom-network"
    subnetwork = google_compute_subnetwork.private-subnet.name # Replace with a reference or self link to your subnet, in quotes
  }

  lifecycle {
    ignore_changes = all
  }
}

# Create Private Subnet for DataBase
resource "google_compute_subnetwork" "db-subnet" {
  name          = "db-subnet"
  ip_cidr_range = "10.10.3.0/24"
  network       = google_compute_network.vpc.name
  region = "us-central1"

  lifecycle {
    ignore_changes = all
  }
}

## Create a VM in the db-subnet

resource "google_compute_instance" "db-vm" {
  project      = var.project_name
  zone         = "us-central1-b"
  name         = "db-vm"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = "my-custom-network"
    subnetwork = google_compute_subnetwork.db-subnet.name # Replace with a reference or self link to your subnet, in quotes
  }

  lifecycle {
    ignore_changes = all
  }
}

# Create a firewall to allow SSH connection from the specified source range
resource "google_compute_firewall" "rules" {
  project = var.project_name
  name    = "allow-ssh"
  network = "my-custom-network" 
 
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  #source_ranges = ["35.235.240.0/20"]
  source_ranges = ["35.235.240.0/20"]

  lifecycle {
    ignore_changes = all
  }
}

## Create IAP SSH permissions for your test instance

/*
 resource "google_project_iam_member" "project1" {
   project = var.project_name
    role    = "roles/iap.tunnelResourceAccessor"
    member  = "serviceAccount:terraform@alert-flames-276807.iam.gserviceaccount.com"
 }
*/

## Create Cloud Router

resource "google_compute_router" "router" {
  project = var.project_name
  name    = "nat-router"
  network = "my-custom-network"
  region  = "us-central1"

  lifecycle {
    ignore_changes = all
  }
}

## Create Nat Gateway

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  lifecycle {
    ignore_changes = all
  }
}

#for Creating the Database
/*

resource "google_compute_global_address" "private_ip_address" {
  #name          = google_compute_network.my-custom-network.name
  name          = google_compute_network.vpc.name
  #name          = google_compute_subnetwork.db-subnet.name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.name
  #network       = google_compute_subnetwork.db-subnet.name
  
}


resource "google_service_networking_connection" "private_vpc_connection" {

  network                 = google_compute_network.vpc.id
  #network                 = google_compute_subnetwork.db-subnet.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]


}     

# Create MSSql Database

resource "google_sql_database_instance" "mysql-from-tf"{
  name = "cloud-mysql"
  region = "us-central1"
  deletion_protection = false
  database_version = "MYSQL_8_0"
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  #depends_on       = [google_compute_subnetwork.db-subnet.name]
  #depends_on       = [google_compute_network.my-custom-network.name]
  
  settings {
    tier = "db-n1-standard-1"
    availability_type = "REGIONAL"
    disk_size = 20
    disk_type = "PD_SSD"
     backup_configuration {
      binary_log_enabled = true
                 enabled = true        
    } 
  ip_configuration {

      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
      #private_network = google_compute_subnetwork.db-subnet.self_link
        
    }    
  }

  lifecycle {
    ignore_changes = all
  }

}


resource "google_sql_database" "database" {
name = "quickstart_db"
instance = "${google_sql_database_instance.mysql-from-tf.name}"
charset = "utf8"
collation = "utf8_general_ci"

lifecycle {
    ignore_changes = all
  }
}


resource "google_sql_user" "users" {
  name = "root"
  password = "Abcd1234"
  host = "%"
  instance = "${google_sql_database_instance.mysql-from-tf.name}"

  lifecycle {
    ignore_changes = all
  }
}   

*/