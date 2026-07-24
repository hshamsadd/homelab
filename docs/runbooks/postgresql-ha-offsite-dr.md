# PostgreSQL HA off-site DR

## Current production state

Production PostgreSQL runs on CloudNativePG cluster:

- Namespace: `production`
- Cluster: `central-postgres-ha`
- Instances: `2`
- Current primary at migration completion: `central-postgres-ha-2`
- Application database currently used by Wallabag: `wallabag`
- Wallabag database host: `central-postgres-ha-rw.production.svc.cluster.local`

Legacy cluster `central-postgres` was retired after:
- Wallabag was migrated to `central-postgres-ha`
- HA backup completed successfully
- Legacy final backup completed successfully
- Legacy PV reclaim policy was changed to `Retain`
- Legacy CNPG cluster was deleted

## Local backup source

CloudNativePG writes backups/WALs to production MinIO through the Barman Cloud Plugin.

- ObjectStore CR: `production/minio-postgres-backups`
- MinIO bucket: `postgres-backups`
- Backup path inside MinIO: `postgres-backups/`
- HA scheduled backup: `production/central-postgres-ha-nightly-backup`
- HA scheduled backup cron: `0 0 3 * * *`

Check HA backup state:

```bash
kubectl -n production get scheduledbackup central-postgres-ha-nightly-backup \
  -o custom-columns='NAME:.metadata.name,CLUSTER:.spec.cluster.name,SCHEDULE:.spec.schedule,SUSPEND:.spec.suspend'

kubectl -n production get cluster central-postgres-ha -o json |
  jq '{
    primary: .status.currentPrimary,
    phase: .status.phase,
    conditions: [
      .status.conditions[]
      | select(.type == "ContinuousArchiving" or .type == "LastBackupSucceeded")
      | {type: .type, status: .status, reason: .reason}
    ]
  }'



  Off-site destination

OCI Object Storage bucket:

Namespace: axc00uy8zwuh
Bucket: postgres-backups-dr
S3-compatible endpoint: https://axc00uy8zwuh.compat.objectstorage.eu-amsterdam-1.oci.customer-oci.com
Terraform root: terraform/environments/cloud/oci/object-storage-prod
HCP Terraform workspace: oci-object-storage-prod

The bucket and writer IAM resources are managed by Terraform.

Mirror automation

Kubernetes CronJob:

Namespace: production
CronJob: postgres-backups-dr-mirror
Schedule: 30 3 * * *
Time zone: Etc/UTC
Source: local/postgres-backups
Destination: oci/postgres-backups-dr
Command uses mc mirror --overwrite --preserve
It does not delete remote objects.