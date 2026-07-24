data "oci_objectstorage_namespace" "current" {
  compartment_id = var.tenancy_ocid
}

resource "oci_objectstorage_bucket" "postgres_backups_dr" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.current.namespace
  name           = var.bucket_name

  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  auto_tiering          = "Disabled"
  versioning            = "Enabled"
  object_events_enabled = false

  freeform_tags = {
    managed-by  = "terraform"
    environment = "production"
    purpose     = "postgresql-offsite-dr"
  }

  lifecycle {
    prevent_destroy = true
  }
}
