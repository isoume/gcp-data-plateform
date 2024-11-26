variable "name" {
  description = "Nom du bucket"
  type        = string
}

variable "region" {
  description = "Region du bucket"
  type        = string
}

variable "storage_class" {
  description = "Classe de stockage du bucket"
  type        = string
}

variable "bucket_creators" {
  type =  set(string)
}

variable "bucket_legacy_readers" {
  type = set(string)
}