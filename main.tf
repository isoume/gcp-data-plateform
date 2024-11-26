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

resource "google_compute_router" "my_router" {
  name    = "my-router"
  region  = google_compute_subnetwork.private_subnet.region
  network = google_compute_network.vpc_doctolib.id

  bgp {
    asn = 64514
  }
}


# Step 2: Create a Cloud NAT
resource "google_compute_router_nat" "my_nat" {
  name   = "my-cloud-nat"
  router = google_compute_router.my_router.name
  region = var.private_subnet_region # Same region as your Cloud Router

  nat_ip_allocate_option = "AUTO_ONLY" # Automatically allocated external IPs for NAT
  # Enable NAT for the specified subnet(s)
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Target specific subnets for NAT

  # Define the subnetwork(s) to use for NAT

}

# firewall.tf
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_doctolib.id

  allow {
    protocol = "tcp"
    ports    = ["22"] # Open SSH port
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"] # Allow from anywhere (customize for security)
}

# Firewall Rule: Allow All Egress Traffic
resource "google_compute_firewall" "allow_all_egress" {
  name    = "allow-all-egress"
  network = google_compute_network.vpc_doctolib.id

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}



resource "google_service_account" "continuous_delevery_vm_sa" {
  account_id   = var.vm_continoues_delevery_sa_name
  display_name = var.vm_continoues_delevery_sa_description
}

resource "google_project_iam_member" "continuous_delevery_vm_sa_role" {
  for_each = var.vm_continues_delevery_sa_roles

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.continuous_delevery_vm_sa.email}"
}

resource "google_service_account" "data_processing_vm_sa" {
  account_id   = var.vm_dataprocessing_sa_name
  display_name = var.vm_dataprocessing_sa_description
}

resource "google_service_account_iam_member" "allow_impersonation_cd_data_processing" {
  service_account_id = "projects/doctolib-data-dev/serviceAccounts/${google_service_account.data_processing_vm_sa.email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.continuous_delevery_vm_sa.email}"
}


module "storage_data_doctolib" {
  source                = "./modules/bucket"
  name                  = "${var.project}-${var.bucket_storage_name}"
  region                = var.region
  bucket_creators       = ["serviceAccount:${google_service_account.data_processing_vm_sa.email}"]
  bucket_legacy_readers = ["serviceAccount:${google_service_account.data_processing_vm_sa.email}"]
  storage_class         = "STANDARD"
}

module "backup_data_doctolib" {
  source                = "./modules/bucket"
  name                  = "${var.project}-${var.bucket_backup_name}"
  region                = var.region
  bucket_creators       = []
  bucket_legacy_readers = []
  storage_class         = "ARCHIVE"
}


resource "google_compute_instance" "data_processing_vm" {
  name         = "${var.vm_dataprocessing_name}-${var.env}"
  machine_type = "e2-micro"
  zone         = var.vm_dataprocessing_name_zone
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
    email = google_service_account.data_processing_vm_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform", # Recommended: broad permissions for general compute tasks
    ]
  }

  allow_stopping_for_update = true

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

resource "google_compute_firewall" "jenkins-allow-http" {

  name    = "jenkins-allow-http"
  network = google_compute_network.vpc_doctolib.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"] # Allow traffic from anywhere (can be restricted if needed)

  target_tags = ["jenkins-server"] # Apply the rule only to instances with this tag
}



resource "google_compute_instance" "continuous_delevery_vm" {
  name = "${var.vm_continoues_delevery_name}-${var.env}"
  #e2-medium
  #e2-micro
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

    access_config {
      # It automatically assigns an ephemeral public IP
    }
  }


  service_account {
    email = google_service_account.continuous_delevery_vm_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform", # Recommended: broad permissions for general compute tasks
    ]
  }

  tags = ["jenkins-server"] # Assign the target tag to the instance

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


resource "google_compute_global_address" "private_google_access" {
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_doctolib.id
}

resource "google_service_networking_connection" "private_connection" {
  network = google_compute_network.vpc_doctolib.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_google_access.name
  ]
}


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


resource "google_compute_firewall" "allow_private_subnet_traffic" {
  name    = "allow-private-subnet-traffic"
  network = google_compute_network.vpc_doctolib.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = [var.private_subnet_range_ip_cidr]
}

# Create a database within the instance
resource "google_sql_database" "api_database" {
  name     = "api_database_v2"
  instance = google_sql_database_instance.database_doctolib.name
}

# Grant IAM roles to the VM's Service Account
resource "google_project_iam_member" "sql_client_role" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.data_processing_vm_sa.email}"
}