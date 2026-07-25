# Staging Barman identity closeout

Date: 2026-07-26

## Change

The staging CloudNativePG recovery configuration now explicitly uses:

- Database: `wallabag`
- Owner: `wallabag_user`
- Barman server identity: `central-postgres-ha`

The rendered staging configuration contains no WAL-writing plugin. The large
obsolete commented blocks were left unchanged because their removal was
optional and unrelated to the functional fix.

## Recovery evidence

- Backup CR: `staging-barman-source-20260725195133`
- Backup status: `completed`
- Barman backup ID: `backup-20260725195135`
- Post-backup marker: `STAGING_BARMAN_IDENTITY_20260725T195146Z`
- Archived marker WAL: `000000020000000000000021`
- Test method: isolated Cluster in the `staging` namespace
- Test Cluster: `central-postgres-barman-identity-test`
- Result: healthy with one of one instances ready
- Recovered database and owner: `wallabag` / `wallabag_user`
- The post-backup marker was recovered with its original timestamp
- Roles, memberships, and extensions matched production
- All 17 non-temporary table names and exact row counts matched production
- TCP password authentication succeeded as `wallabag_user`
- The recovered server reported `pg_is_in_recovery() = false`

Password authentication used the CNPG-generated application secret belonging
to the isolated recovery Cluster. Production and staging Wallabag Vault
credentials were not copied or changed.

## Object-store access

The existing staging secret `cnpg-minio-production-fallback-vault` represents
a separate MinIO identity. That identity was provisioned with the
`staging-postgres-backups-readonly` policy and authenticated successfully.

The policy allows bucket-location lookup, bucket listing, and object reads for
`postgres-backups`. It does not allow object writes or deletion.

## Safety and cleanup

- Production Cluster specification was unchanged.
- Production CNPG Pod UIDs, nodes, and restart totals matched the baseline.
- Active staging CNPG Pod UID, node, and restart total matched the baseline.
- Production remained healthy with two of two instances ready.
- Active staging remained healthy with one of one instances ready.
- Production Wallabag continued returning HTTP 302.
- Both Argo CD applications remained Synced and Healthy.
- The final Kustomization built and passed server dry-run.
- The isolated Cluster, PVC, dynamically provisioned PV, and temporary
  LimitRange were removed.
- The live production validation schema was removed after evidence capture.
- The read-only MinIO identity remains for future staging recovery.

Raw closeout output was captured under
`/tmp/cnpg-staging-barman-closeout-20260725T184958Z`.

## Boundary

The accepted isolated-restore path was used; the active staging database was
not recreated.

Before intentionally recreating active staging from production, review its
current Wallabag database and Vault credential mapping against the recovered
`wallabag` database and `wallabag_user`.