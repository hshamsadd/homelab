resource "oci_identity_user" "postgres_dr_writer" {
  compartment_id = var.tenancy_ocid
  name           = "postgres-backups-dr-writer"
  email          = "hshamadd@gmail.com"
  description    = "K3s writer for off-site PostgreSQL backups."
}

resource "oci_identity_group" "postgres_dr_writers" {
  compartment_id = var.tenancy_ocid
  name           = "postgres-backups-dr-writers"
  description    = "Writers for the PostgreSQL off-site DR bucket."
}

resource "oci_identity_user_group_membership" "postgres_dr_writer" {
  group_id = oci_identity_group.postgres_dr_writers.id
  user_id  = oci_identity_user.postgres_dr_writer.id
}

resource "oci_identity_policy" "postgres_dr_writer" {
  compartment_id = var.tenancy_ocid
  name           = "postgres-backups-dr-writer"
  description    = "Allow the DR writer to read and upload objects without deleting them."

  statements = [
    "Allow group id ${oci_identity_group.postgres_dr_writers.id} to read buckets in tenancy where target.bucket.name = '${oci_objectstorage_bucket.postgres_backups_dr.name}'",
    "Allow group id ${oci_identity_group.postgres_dr_writers.id} to manage objects in tenancy where all {target.bucket.name = '${oci_objectstorage_bucket.postgres_backups_dr.name}', any {request.permission = 'OBJECT_INSPECT', request.permission = 'OBJECT_READ', request.permission = 'OBJECT_CREATE', request.permission = 'OBJECT_OVERWRITE'}}"
  ]
}
