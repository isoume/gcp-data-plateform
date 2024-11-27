provider "google" {
  project = var.project
  region  = var.region
  access_token = length(var.tf_access_token) > 0 ? var.tf_access_token : null
}

provider "google-beta" {
  project = var.project
  region  = var.region
  access_token = length(var.tf_access_token) > 0 ? var.tf_access_token : null
}