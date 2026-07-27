# Health Ingester

Private Health Connect Webhook receiver for Hussein's homelab.

The service:

- accepts HC Webhook JSON at `POST /v1/health-connect`;
- requires an `Authorization: Bearer ...` header;
- retains every complete payload in PostgreSQL `JSONB`;
- deduplicates individual records using a deterministic SHA-256 hash;
- stores all current and future array-based Health Connect types;
- exposes normalized PostgreSQL views for Grafana;
- exposes operational metrics at `/metrics`, without health values or payloads;
- never logs request bodies, database passwords, or webhook tokens.

## HTTP endpoints

| Endpoint | Purpose |
| --- | --- |
| `POST /v1/health-connect` | Authenticated HC Webhook ingestion |
| `GET /healthz` | Process liveness |
| `GET /readyz` | PostgreSQL readiness |
| `GET /metrics` | Prometheus operational metrics |

## Required environment

| Variable | Example |
| --- | --- |
| `DATABASE_HOST` | `central-postgres-dev-rw.dev.svc.cluster.local` |
| `DATABASE_PORT` | `5432` |
| `DATABASE_NAME` | `health_dev` |
| `DATABASE_USER` | `health_ingester_dev_user` |
| `DATABASE_PASSWORD` | supplied from a Kubernetes Secret |
| `GRAFANA_DATABASE_ROLE` | `health_grafana_dev_user` |
| `WEBHOOK_TOKEN` | supplied from Vault |

Optional:

- `LISTEN_ADDRESS` defaults to `:8080`.
- `DATABASE_SSLMODE` defaults to `disable` for the in-cluster CNPG connection.

## Grafana views

- `health.record_inventory`
- `health.activity_events`
- `health.sleep_sessions`
- `health.sleep_stages`
- `health.sleep_stage_totals`
- `health.measurements`
- `health.latest_measurements`
- `health.blood_pressure`
- `health.skin_temperature`
- `health.hydration_events`
- `health.nutrition_events`
- `health.exercise_sessions`
- `health.body_composition`

The original records remain available in `health.records`, and complete webhook
batches remain in `health.ingest_batches`.

`health.measurements` normalizes heart rate, resting heart rate, HRV, oxygen
saturation, respiratory rate, body and basal temperatures, VO2 max, body fat,
lean body mass, bone mass, weight, height, blood glucose, and basal metabolic
rate. `health.body_composition` derives BMI from each weight record and the
nearest available height measurement. Empty views are expected until a source
device or app writes the corresponding Health Connect records.
