# Production CloudNativePG recovery

This directory is the authoritative recovery path for the production
CloudNativePG database.

It is intentionally outside the active production Argo CD Kustomization.
Never add these recovery Kustomizations to `stack-production`.

## Current production identity

- Namespace: `production`
- Cluster: `central-postgres-ha`
- Database: `wallabag`
- Owner and login role: `wallabag_user`
- ObjectStore: `minio-postgres-backups`
- Current Barman source identity: `central-postgres-ha`
- StorageClass: `local-path`
- Eligible nodes: `cnpg-ha=true`, currently `server` and `worker-2`

The active manifest under
`gitops/apps/environments/production/patches/cloudnative-pg/`
is runtime desired state. It is not the initial greenfield entry point because
its Barman plugin writes WAL for the running Cluster.

## Recovery entry points

### Drill

Use `gitops/recovery/production/drill`.

This creates `production/central-postgres-ha-recovery` and can coexist with
the healthy production Cluster.

### Real greenfield recovery

Use `gitops/recovery/production/greenfield`.

This creates `production/central-postgres-ha`, preserving Wallabag's existing
database hostname:

`central-postgres-ha-rw.production.svc.cluster.local`

Do not apply the greenfield Kustomization while an existing
`central-postgres-ha` Cluster is present.

Both entry points:

- begin with one PostgreSQL instance;
- recover database `wallabag`;
- preserve owner `wallabag_user`;
- recover from Barman server `central-postgres-ha`;
- use only nodes labelled `cnpg-ha=true`;
- have no `spec.plugins` section;
- cannot write WAL into the recovery source lineage.

## Required credential bridge

The recovery manifests reference the runtime-only basic-auth Secret:

`production/cnpg-wallabag-recovery-credentials`

Create it from the existing Vault-managed Wallabag Secret without decoding or
printing the password:

    kubectl -n production get secret wallabag-credentials-vault -o json |
      jq '{
        apiVersion: "v1",
        kind: "Secret",
        metadata: {
          name: "cnpg-wallabag-recovery-credentials",
          namespace: "production"
        },
        type: "kubernetes.io/basic-auth",
        data: {
          username: .data.DATABASE_USER,
          password: .data.DATABASE_PASSWORD
        }
      }' |
      kubectl create -f -

Never commit this Secret or its values to Git.

## Recovery drill

Create the credential bridge, then run:

    kubectl apply -k gitops/recovery/production/drill

    kubectl -n production wait \
      --for=condition=Ready \
      cluster/central-postgres-ha-recovery \
      --timeout=30m

Validate:

- the post-backup WAL marker;
- database `wallabag`;
- owner and role `wallabag_user`;
- table names and exact row counts;
- PostgreSQL extensions;
- password authentication through the recovery RW Service;
- absence of `spec.plugins`;
- continued production health.

After the drill:

    kubectl -n production delete \
      cluster central-postgres-ha-recovery \
      --wait=true

    kubectl -n production delete \
      secret cnpg-wallabag-recovery-credentials \
      --wait=true

Verify that its pod, PVC, dynamic PV, Services and temporary authentication Job
are also absent.

## Real greenfield recovery

Before recovery:

1. Verify that the old `central-postgres-ha` Cluster no longer exists.
2. Prevent `stack-production` from reconciling the active Cluster manifest.
3. Restore and verify MinIO and `minio-postgres-backups`.
4. Restore and verify Vault Secrets Operator and
   `wallabag-credentials-vault`.
5. Confirm `server` and `worker-2` have `cnpg-ha=true`.
6. Create `cnpg-wallabag-recovery-credentials`.

Start recovery:

    kubectl apply -k gitops/recovery/production/greenfield

    kubectl -n production wait \
      --for=condition=Ready \
      cluster/central-postgres-ha \
      --timeout=30m

Validate the database before enabling WAL archiving or resuming Argo CD.

The initial recovered Cluster intentionally has one instance and no WAL
archiver.

Before resuming `stack-production`, change the active production Cluster's
Barman writer to a new, empty server identity, for example:

    plugins:
      - name: barman-cloud.cloudnative-pg.io
        isWALArchiver: true
        parameters:
          barmanObjectName: minio-postgres-backups
          serverName: central-postgres-ha-recovered-YYYYMMDDTHHMMSSZ

Do not use `central-postgres-ha` as the recovered Cluster's writer identity.
That is the existing non-empty recovery source.

After resuming Argo CD:

1. Confirm the Cluster scales to two healthy instances.
2. Confirm placement on `server` and `worker-2`.
3. Confirm Wallabag returns HTTP 302.
4. Confirm continuous WAL archiving succeeds.
5. Create an immediate backup in the new writer lineage.
6. Update both recovery entry points to use that verified lineage as their
   source for the next disaster.
7. Use another new empty writer identity during the next recovery.

Never enable `cnpg.io/skipEmptyWalArchiveCheck`. Bypassing that protection can
overwrite backup or WAL history.

## Verified drill evidence

Verified on 2026-07-24 UTC.

- Backup CR: `greenfield-closeout-20260724222713`
- Barman backup: `backup-20260724222715`
- Post-backup marker: `GREENFIELD_CLOSEOUT_20260724T222729Z`
- Marker WAL: `000000020000000000000013`
- Recovery Cluster: `central-postgres-ha-recovery`
- Recovery node: `worker-2`
- Database: `wallabag`
- Owner: `wallabag_user`
- Password authentication: passed
- Authenticated public-table count: 16
- Exact table row counts: matched
- Table list: matched
- Role attributes: matched
- PostgreSQL extensions: matched
- Recovery promotion: passed
- Recovery WAL-writing plugin: absent
- Production remained healthy at two of two instances
- Production pod UIDs, nodes and restart counts remained unchanged
- Wallabag remained HTTP 302
- Temporary Cluster, pod, PVC, PV, Services, Job and Secret were removed

CloudNativePG recovery documentation:

https://cloudnative-pg.io/docs/1.29/recovery/