CREATE OR REPLACE VIEW health.record_inventory AS
SELECT
    data_type,
    count(*) AS record_count,
    min(COALESCE(start_time, observed_at, inserted_at)) AS first_recorded_at,
    max(COALESCE(end_time, observed_at, inserted_at)) AS last_recorded_at
FROM health.records
GROUP BY data_type;

CREATE OR REPLACE VIEW health.sleep_sessions AS
SELECT
    id,
    COALESCE(
        (data ->> 'session_end_time')::timestamptz,
        observed_at
    ) AS session_end_time,
    COALESCE(
        (data ->> 'session_end_time')::timestamptz,
        observed_at
    ) - make_interval(
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

CREATE OR REPLACE VIEW health.sleep_stage_totals AS
SELECT
    sleep_record_id,
    stage,
    sum(duration_seconds)::bigint AS duration_seconds
FROM health.sleep_stages
GROUP BY sleep_record_id, stage;

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
    'basal_metabolic_rate'
);

CREATE OR REPLACE VIEW health.latest_measurements AS
SELECT DISTINCT ON (data_type)
    id,
    data_type,
    observed_at,
    value,
    unit,
    data
FROM health.measurements
WHERE value IS NOT NULL
ORDER BY data_type, observed_at DESC NULLS LAST, id DESC;

CREATE OR REPLACE VIEW health.blood_pressure AS
SELECT
    id,
    observed_at,
    (data ->> 'systolic')::double precision AS systolic_mmhg,
    (data ->> 'diastolic')::double precision AS diastolic_mmhg,
    (
        (data ->> 'systolic')::double precision
        - (data ->> 'diastolic')::double precision
    ) AS pulse_pressure_mmhg,
    (
        (data ->> 'diastolic')::double precision
        + (
            (data ->> 'systolic')::double precision
            - (data ->> 'diastolic')::double precision
        ) / 3.0
    ) AS mean_arterial_pressure_mmhg,
    data
FROM health.records
WHERE data_type = 'blood_pressure';

CREATE OR REPLACE VIEW health.skin_temperature AS
SELECT
    id,
    observed_at,
    (data ->> 'baseline_celsius')::double precision AS baseline_celsius,
    (data ->> 'delta_celsius')::double precision AS delta_celsius,
    data ->> 'measurement_location' AS measurement_location,
    data
FROM health.records
WHERE data_type = 'skin_temperature';

CREATE OR REPLACE VIEW health.hydration_events AS
SELECT
    id,
    start_time,
    end_time,
    (data ->> 'liters')::double precision AS liters,
    data
FROM health.records
WHERE data_type = 'hydration';

CREATE OR REPLACE VIEW health.nutrition_events AS
SELECT
    id,
    start_time,
    end_time,
    data ->> 'name' AS name,
    (data ->> 'calories')::double precision AS calories,
    (data ->> 'protein_grams')::double precision AS protein_grams,
    (data ->> 'carbs_grams')::double precision AS carbs_grams,
    (data ->> 'fat_grams')::double precision AS fat_grams,
    (data ->> 'sugar_grams')::double precision AS sugar_grams,
    (data ->> 'dietary_fiber_grams')::double precision AS dietary_fiber_grams,
    (data ->> 'sodium_grams')::double precision AS sodium_grams,
    data
FROM health.records
WHERE data_type = 'nutrition';

CREATE OR REPLACE VIEW health.exercise_sessions AS
SELECT
    id,
    COALESCE(start_time, (data ->> 'start_time')::timestamptz) AS start_time,
    COALESCE(end_time, (data ->> 'end_time')::timestamptz) AS end_time,
    data ->> 'type' AS exercise_type,
    (data ->> 'duration_seconds')::bigint AS duration_seconds,
    (data ->> 'distance_meters')::double precision AS distance_meters,
    (data ->> 'steps')::bigint AS steps,
    (data ->> 'avg_cadence_spm')::double precision AS average_cadence_spm,
    (data ->> 'max_cadence_spm')::double precision AS maximum_cadence_spm,
    (data ->> 'stride_length_m')::double precision AS stride_length_meters,
    data
FROM health.records
WHERE data_type = 'exercise';

CREATE OR REPLACE VIEW health.body_composition AS
SELECT
    weight.id AS weight_record_id,
    weight.observed_at,
    weight.value AS weight_kilograms,
    height.height_record_id,
    height.height_observed_at,
    height.height_meters,
    CASE
        WHEN height.height_meters > 0 THEN
            round(
                (
                    weight.value
                    / power(height.height_meters, 2)
                )::numeric,
                2
            )::double precision
        ELSE NULL
    END AS bmi
FROM health.measurements AS weight
LEFT JOIN LATERAL (
    SELECT
        candidate.id AS height_record_id,
        candidate.observed_at AS height_observed_at,
        candidate.value AS height_meters
    FROM health.measurements AS candidate
    WHERE
        candidate.data_type = 'height'
        AND candidate.value > 0
    ORDER BY
        abs(
            EXTRACT(
                EPOCH FROM (candidate.observed_at - weight.observed_at)
            )
        ) ASC NULLS LAST,
        candidate.observed_at DESC,
        candidate.id DESC
    LIMIT 1
) AS height ON true
WHERE weight.data_type = 'weight';
