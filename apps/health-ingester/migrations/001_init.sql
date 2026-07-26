CREATE SCHEMA IF NOT EXISTS health;

CREATE TABLE IF NOT EXISTS health.ingest_batches (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    received_at         timestamptz NOT NULL DEFAULT now(),
    source_timestamp    timestamptz NOT NULL,
    app_version         text NOT NULL,
    payload_hash        bytea NOT NULL UNIQUE,
    received_records    integer NOT NULL DEFAULT 0 CHECK (received_records >= 0),
    inserted_records    integer NOT NULL DEFAULT 0 CHECK (inserted_records >= 0),
    duplicate_records   integer NOT NULL DEFAULT 0 CHECK (duplicate_records >= 0),
    raw_payload         jsonb NOT NULL CHECK (jsonb_typeof(raw_payload) = 'object')
);

CREATE TABLE IF NOT EXISTS health.records (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id        bigint NOT NULL REFERENCES health.ingest_batches(id),
    data_type       text NOT NULL,
    start_time      timestamptz,
    end_time        timestamptz,
    observed_at     timestamptz,
    record_hash     bytea NOT NULL UNIQUE,
    data            jsonb NOT NULL CHECK (jsonb_typeof(data) = 'object'),
    inserted_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS records_data_type_observed_at_idx
    ON health.records (data_type, observed_at DESC);

CREATE INDEX IF NOT EXISTS records_data_type_start_time_idx
    ON health.records (data_type, start_time DESC);

CREATE INDEX IF NOT EXISTS records_batch_id_idx
    ON health.records (batch_id);

CREATE OR REPLACE VIEW health.activity_events AS
SELECT
    id,
    data_type,
    start_time,
    end_time,
    CASE data_type
        WHEN 'steps' THEN (data ->> 'count')::double precision
        WHEN 'distance' THEN (data ->> 'meters')::double precision
        WHEN 'active_calories' THEN (data ->> 'calories')::double precision
        WHEN 'total_calories' THEN (data ->> 'calories')::double precision
        ELSE NULL
    END AS value,
    CASE data_type
        WHEN 'steps' THEN 'steps'
        WHEN 'distance' THEN 'meters'
        WHEN 'active_calories' THEN 'kilocalories'
        WHEN 'total_calories' THEN 'kilocalories'
        ELSE NULL
    END AS unit,
    data
FROM health.records
WHERE data_type IN ('steps', 'distance', 'active_calories', 'total_calories');

CREATE OR REPLACE VIEW health.sleep_sessions AS
SELECT
    id,
    observed_at AS session_end_time,
    observed_at - make_interval(
        secs => COALESCE((data ->> 'duration_seconds')::double precision, 0)
    ) AS session_start_time,
    (data ->> 'duration_seconds')::bigint AS duration_seconds,
    data -> 'stages' AS stages
FROM health.records
WHERE data_type = 'sleep';

CREATE OR REPLACE VIEW health.sleep_stages AS
SELECT
    r.id AS sleep_record_id,
    stage ->> 'stage' AS stage,
    (stage ->> 'start_time')::timestamptz AS start_time,
    (stage ->> 'end_time')::timestamptz AS end_time,
    (stage ->> 'duration_seconds')::bigint AS duration_seconds
FROM health.records AS r
CROSS JOIN LATERAL jsonb_array_elements(
    COALESCE(r.data -> 'stages', '[]'::jsonb)
) AS stage
WHERE r.data_type = 'sleep';

CREATE OR REPLACE VIEW health.measurements AS
SELECT
    id,
    data_type,
    observed_at,
    CASE data_type
        WHEN 'heart_rate' THEN (data ->> 'bpm')::double precision
        WHEN 'resting_heart_rate' THEN (data ->> 'bpm')::double precision
        WHEN 'heart_rate_variability' THEN (data ->> 'rmssd_millis')::double precision
        WHEN 'oxygen_saturation' THEN (data ->> 'percentage')::double precision
        WHEN 'respiratory_rate' THEN (data ->> 'rate')::double precision
        WHEN 'weight' THEN (data ->> 'kilograms')::double precision
        WHEN 'height' THEN (data ->> 'meters')::double precision
        WHEN 'body_fat' THEN (data ->> 'percentage')::double precision
        WHEN 'lean_body_mass' THEN (data ->> 'kilograms')::double precision
        WHEN 'bone_mass' THEN (data ->> 'kilograms')::double precision
        WHEN 'vo2_max' THEN (data ->> 'ml_per_kg_per_min')::double precision
        WHEN 'body_temperature' THEN (data ->> 'celsius')::double precision
        WHEN 'basal_body_temperature' THEN (data ->> 'celsius')::double precision
        WHEN 'blood_glucose' THEN (data ->> 'mmol_per_liter')::double precision
        WHEN 'hydration' THEN (data ->> 'liters')::double precision
        WHEN 'basal_metabolic_rate' THEN (data ->> 'watts')::double precision
        ELSE NULL
    END AS value,
    CASE data_type
        WHEN 'heart_rate' THEN 'bpm'
        WHEN 'resting_heart_rate' THEN 'bpm'
        WHEN 'heart_rate_variability' THEN 'milliseconds'
        WHEN 'oxygen_saturation' THEN 'percent'
        WHEN 'respiratory_rate' THEN 'breaths_per_minute'
        WHEN 'weight' THEN 'kilograms'
        WHEN 'height' THEN 'meters'
        WHEN 'body_fat' THEN 'percent'
        WHEN 'lean_body_mass' THEN 'kilograms'
        WHEN 'bone_mass' THEN 'kilograms'
        WHEN 'vo2_max' THEN 'ml_per_kg_per_min'
        WHEN 'body_temperature' THEN 'celsius'
        WHEN 'basal_body_temperature' THEN 'celsius'
        WHEN 'blood_glucose' THEN 'mmol_per_liter'
        WHEN 'hydration' THEN 'liters'
        WHEN 'basal_metabolic_rate' THEN 'watts'
        ELSE NULL
    END AS unit,
    data
FROM health.records
WHERE data_type IN (
    'heart_rate',
    'resting_heart_rate',
    'heart_rate_variability',
    'oxygen_saturation',
    'respiratory_rate',
    'weight',
    'height',
    'body_fat',
    'lean_body_mass',
    'bone_mass',
    'vo2_max',
    'body_temperature',
    'basal_body_temperature',
    'blood_glucose',
    'hydration',
    'basal_metabolic_rate'
);
