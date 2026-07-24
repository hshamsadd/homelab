variable "compartment_id" {
  type        = string
  description = "OCI compartment containing the DR bucket."
}

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID."
}

variable "user_ocid" {
  type        = string
  description = "OCI Terraform user OCID."
}

variable "fingerprint" {
  type        = string
  description = "OCI API signing-key fingerprint."
}

variable "region" {
  type        = string
  description = "OCI region."
}

variable "oci_private_key" {
  type        = string
  description = "OCI API signing private key supplied by Vault at runtime."
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  description = "Dedicated off-site PostgreSQL backup bucket."
  default     = "postgres-backups-dr"
}
