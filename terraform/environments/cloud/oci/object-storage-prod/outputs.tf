output "bucket_name" {
  value = oci_objectstorage_bucket.postgres_backups_dr.name
}

output "bucket_id" {
  value = oci_objectstorage_bucket.postgres_backups_dr.id
}

output "namespace" {
  value = data.oci_objectstorage_namespace.current.namespace
}

output "s3_endpoint" {
  value = "https://${data.oci_objectstorage_namespace.current.namespace}.compat.objectstorage.${var.region}.oci.customer-oci.com"
}

output "backup_writer_user_id" {
  value = oci_identity_user.postgres_dr_writer.id
}

output "backup_writer_group_id" {
  value = oci_identity_group.postgres_dr_writers.id
}
