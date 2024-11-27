project = "doctolib-data-dev"
region  = "EU"
env     = "dev"


private_subnet_region  = "europe-west1"

private_subnet_range_ip_cidr = "10.10.1.0/24"

public_subnet_region = "europe-west2"

public_subnet_range_ip_cidr = "10.10.2.0/24"

bucket_storage_name ="doctolib-storage-data"

bucket_backup_name  = "backup-storage-data"

vm_continoues_delevery_name = "continoues-delevery-data-ops"

vm_continoues_delevery_sa_name = "continoues-delevery-sa"

vm_continoues_delevery_sa_description = "continoues-delevery-sa"

vm_continues_delevery_sa_roles = ["roles/compute.instanceAdmin.v1", "roles/iap.tunnelResourceAccessor"]

vm_continoues_delevery_zone = "europe-west2-b"

list_private_vms = {
       "vm1" = {
          vm_dataprocessing_name = "worker-data-processing-1"
          vm_dataprocessing_name_zone = "europe-west1-b"
          vm_dataprocessing_sa_name  = "data-processing-sa-1"
          vm_dataprocessing_sa_description = "data-processing-sa"
      }
       "vm2" = {
          vm_dataprocessing_name = "worker-data-processing-2"
          vm_dataprocessing_name_zone = "europe-west1-b"
          vm_dataprocessing_sa_name  = "data-processing-sa-2"
          vm_dataprocessing_sa_description = "data-processing-sa"
      }
    }