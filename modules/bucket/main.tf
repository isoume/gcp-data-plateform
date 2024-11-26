resource "google_storage_bucket" "gcs_bucket" {
  name          = var.name
  location      = var.region
  storage_class = var.storage_class
}

resource "google_storage_bucket_iam_member" "gcs_bucket_creators" {
  for_each = var.bucket_creators

  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectCreator"
  member = each.value
}

resource "google_storage_bucket_iam_binding" "gcs_bucket_legacy_readers" {

  bucket  = google_storage_bucket.gcs_bucket.name
  role    = "roles/storage.legacyBucketReader"
  members = var.bucket_legacy_readers
}