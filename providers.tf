provider "google" {
  project = var.project
  region  = var.region
  #access_token = var.tf_access_token
}

provider "google-beta" {
  project = var.project
  region  = var.region
  #access_token = var.tf_access_token
}