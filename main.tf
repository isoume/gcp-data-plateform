resource "google_compute_network" "vpc_doctolib" {
  name                    = "vpc-doclib-${var.env}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name                     = "subnet-private-${var.env}"
  ip_cidr_range            = var.private_subnet_range_ip_cidr
  region                   = var.private_subnet_region
  network                  = google_compute_network.vpc_doctolib.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "public_subnet" {
  name                     = "subnet-public-${var.env}"
  ip_cidr_range            = var.public_subnet_range_ip_cidr
  region                   = var.public_subnet_region
  network                  = google_compute_network.vpc_doctolib.id
  private_ip_google_access = true
}

# Allow the private intance to get package in the internet (router)
resource "google_compute_router" "my_router" {
  name    = "my-router"
  region  = google_compute_subnetwork.private_subnet.region
  network = google_compute_network.vpc_doctolib.id

  bgp {
    asn = 64514
  }
}

# Allow the private intance to get package in the internet (Network Translation Address)
resource "google_compute_router_nat" "my_nat" {
  name                               = "my-cloud-nat"
  router                             = google_compute_router.my_router.name
  region                             = var.private_subnet_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Allow SSH connection for the vm to test connectivity
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_doctolib.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

# Open port for looking upgrade, ...
resource "google_compute_firewall" "allow_all_egress" {
  name    = "allow-all-egress"
  network = google_compute_network.vpc_doctolib.id

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Service account for the vm named (continuous_delevery_vm_sa)
resource "google_service_account" "continuous_delevery_vm_sa" {
  account_id   = var.vm_continoues_delevery_sa_name
  display_name = var.vm_continoues_delevery_sa_description
}

# Allow it necessary roles
resource "google_project_iam_member" "continuous_delevery_vm_sa_role" {
  for_each = var.vm_continues_delevery_sa_roles

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.continuous_delevery_vm_sa.email}"
}

# Service account for the vm named (data_processing_vm_sa)
resource "google_service_account" "data_processing_vm_sa" {
  for_each     = var.list_private_vms
  account_id   = each.value.vm_dataprocessing_sa_name
  display_name = each.value.vm_dataprocessing_sa_description
}

# Allow the SA continuous_delevery_vm_sa serviceAccountUser to data_processing_vm_sa for connect
resource "google_service_account_iam_member" "allow_impersonation_cd_data_processing" {
  for_each     = var.list_private_vms
  service_account_id = "projects/doctolib-data-dev/serviceAccounts/${google_service_account.data_processing_vm_sa[each.key].email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.continuous_delevery_vm_sa.email}"
}

# Storage bucket for input data
module "storage_data_doctolib" {
  source                = "./modules/bucket"
  name                  = "${var.project}-${var.bucket_storage_name}"
  region                = var.region
  bucket_creators       = [for sa in google_service_account.data_processing_vm_sa: "serviceAccount:${sa.email}"]
  bucket_legacy_readers = [for sa in google_service_account.data_processing_vm_sa: "serviceAccount:${sa.email}"]
  storage_class         = "STANDARD"
}

# Storage bucket for ARCHIVE
module "backup_data_doctolib" {
  source                = "./modules/bucket"
  name                  = "${var.project}-${var.bucket_backup_name}"
  region                = var.region
  bucket_creators       = []
  bucket_legacy_readers = []
  storage_class         = "ARCHIVE"
}

# VM that running in the private subnet
resource "google_compute_instance" "data_processing_vm" {
  for_each     = var.list_private_vms
  name         = "${each.value.vm_dataprocessing_name}-${var.env}"
  machine_type = "e2-micro"
  zone         = each.value.vm_dataprocessing_name_zone
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    }
  }
  network_interface {
    network    = google_compute_network.vpc_doctolib.id
    subnetwork = google_compute_subnetwork.private_subnet.id

  }

  service_account {
    email = google_service_account.data_processing_vm_sa[each.key].email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  allow_stopping_for_update = true

  # Install docker for the futur data processing container
  metadata_startup_script = <<-EOT
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  EOT
}

# Open the port 8080 for the final users to access on jenkins-allow-http
resource "google_compute_firewall" "jenkins-allow-http" {

  name    = "jenkins-allow-http"
  network = google_compute_network.vpc_doctolib.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins-server"]
}

#Provision the vm in the public network
resource "google_compute_instance" "continuous_delevery_vm" {
  name = "${var.vm_continoues_delevery_name}-${var.env}"
  # Allow the small to have memory for jenkins and other worker
  machine_type = "e2-small"
  zone         = var.vm_continoues_delevery_zone
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    }
  }
  allow_stopping_for_update = true
  network_interface {
    network    = google_compute_network.vpc_doctolib.id
    subnetwork = google_compute_subnetwork.public_subnet.id
    # Attach a public network ip address
    access_config {
    }
  }

  service_account {
    email = google_service_account.continuous_delevery_vm_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform", # Recommended: broad permissions for general compute tasks
    ]
  }

  tags = ["jenkins-server"] # Assign the target tag to the instance

  # Install Jenkins on startup for cd
  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt update
    sudo apt install -y openjdk-17-jre
    java -version
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins
    systemctl enable jenkins
  EOT
}


resource "google_project_service" "service_networking" {
  service = "servicenetworking.googleapis.com"
  project = var.project
}

# Let create a private peering/connection for the cloud instance
resource "google_compute_global_address" "private_google_access" {
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_doctolib.id
}

# Assume the private connection with the peering
resource "google_service_networking_connection" "private_connection" {
  network = google_compute_network.vpc_doctolib.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_google_access.name
  ]
}
/*
# Create the cloud instances
resource "google_sql_database_instance" "database_doctolib" {
  name             = "dataprocessing-database-${var.env}"
  region           = var.private_subnet_region
  database_version = "MYSQL_8_0"

  depends_on = [google_service_networking_connection.private_connection]
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      private_network = google_compute_network.vpc_doctolib.id
      ipv4_enabled    = false
    }
  }
  deletion_protection = false
}

# Open traffic in the port of cloud sql m(mysql) 3306
resource "google_compute_firewall" "allow_private_subnet_traffic" {
  name    = "allow-private-subnet-traffic"
  network = google_compute_network.vpc_doctolib.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  # Only for the private subnet
  source_ranges = [var.private_subnet_range_ip_cidr]
}

# Grant IAM roles to the VM's Service Account
resource "google_project_iam_member" "sql_client_role" {
  for_each = var.list_private_vms
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.data_processing_vm_sa[each.key].email}"
}
*/