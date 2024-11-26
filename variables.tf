variable "project" {
  description = "The project whoch i want to provision the resource"
  type        = string
}

variable "region" {
  description = "The project whoch i want to provision the resource"
  type        = string
  default     = "europe-west1"
}

variable "env" {
  description = "Defines the deployment environment (e.g., development, staging, production)."
  type        = string
}

variable "private_subnet_region" {
  description = "Specifies the region for the private subnet within the cloud provider's infrastructure."
  type        = string
  default     = "europe-west1"
}

variable "private_subnet_range_ip_cidr" {
  description = "Defines the IP address range in CIDR notation for the private subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "public_subnet_region" {
  description = "Specifies the region for the public subnet."
  type        = string
  default     = "europe-west2"
}

variable "public_subnet_range_ip_cidr" {
  description = "Defines the IP address range in CIDR notation for the public subnet."
  type        = string
  default     = "10.10.2.0/24"
}

variable "bucket_storage_name" {
  description = "Name of the storage bucket used for storing primary data."
  type        = string
  default     = "doctolib-storage-data"
}

variable "bucket_backup_name" {
  description = "Name of the storage bucket used for backups."
  type        = string
  default     = "backup-storage-data"
}

variable "vm_dataprocessing_name" {
  description = "Name of the virtual machine used for data processing tasks."
  type        = string
  default     = "worker-data-processing"
}

variable "vm_dataprocessing_name_zone" {
  description = "Zone where the data processing virtual machine is deployed."
  type        = string
  default     = "europe-west1-b"
}

variable "vm_dataprocessing_sa_name" {
  description = "Name of the service account assigned to the data processing virtual machine."
  type        = string
  default     = "data-processing-sa"
}

variable "vm_dataprocessing_sa_description" {
  description = "Description of the service account assigned to the data processing virtual machine."
  type        = string
  default     = "data-processing-sa"
}

variable "vm_continoues_delevery_name" {
  description = "Name of the virtual machine used for continuous delivery operations."
  type        = string
  default     = "continoues-delevery-data-ops"
}

variable "vm_continoues_delevery_sa_name" {
  description = "Name of the service account assigned to the continuous delivery virtual machine."
  type        = string
  default     = "continoues-delevery-sa"
}

variable "vm_continoues_delevery_sa_description" {
  description = "Description of the service account assigned to the continuous delivery virtual machine."
  type        = string
  default     = "continoues-delevery-sa"
}

variable "vm_continues_delevery_sa_roles" {
  type = set(string)
  default = ["roles/compute.instanceAdmin.v1", "roles/iap.tunnelResourceAccessor"]
}

variable "vm_continoues_delevery_zone" {
  description = "Zone where the continuous delivery virtual machine is deployed."
  type        = string
  default     = "europe-west2-b"
}

variable "service_account_id" {
  description = "The Service Account ID"
  default     = "dataops-provisionning-sa"
}

variable "tf_access_token" {
  type = string
  description = "Access token used for Terraform authentication and API requests."
  default ="UNKWON"
}
