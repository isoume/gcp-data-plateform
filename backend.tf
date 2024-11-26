terraform {
  backend "gcs" {
    bucket = "terraform_backendx"
    prefix = "terraform/state"
  }
}