-- BEGIN AUTHORITATIVE ANALYTICS V2

CREATE TABLE IF NOT EXISTS health.analytics_source_priority (
    data_type   text NOT NULL,
    data_origin text NOT NULL,
    priority    integer NOT NULL CHECK (priority > 0),
    PRIMARY KEY (data_type, data_origin)
);

INSERT INTO health.analytics_source_priority (
    data_type,
    data_origin,
    priority
)
VALUES
    -- Activity
    ('total_calories', 'com.fitbit.FitbitMobile', 10),
    ('total_calories', 'com.google.android.apps.fitness', 20),
    ('total_calories', 'nl.appyhapps.healthsync', 40),

    -- Body composition
    ('weight', 'com.moving.movinglife', 10),
    ('weight', 'com.fitbit.FitbitMobile', 20),
    ('weight', 'nl.appyhapps.healthsync', 30),
    ('weight', 'com.google.android.apps.fitness', 40),

    ('height', 'com.google.android.apps.fitness', 10),
    ('height', 'nl.appyhapps.healthsync', 20),

    ('body_fat', 'com.moving.movinglife', 10),

    -- Vitals currently have one observed source
    ('heart_rate', 'nl.appyhapps.healthsync', 10),
    ('oxygen_saturation', 'nl.appyhapps.healthsync', 10)
ON CONFLICT (data_type, data_origin)
DO UPDATE SET priority = EXCLUDED.priority;


-- Health Connect Webhook is sending steps/distance/active calories as
-- repeated cumulative snapshots. The most recent snapshot for each local
-- day is authoritative; never SUM these raw snapshots.
CREATE OR REPLACE VIEW health.activity_daily AS
WITH base AS (
    SELECT
        ae.id,
        ae.data_type,
        (
            COALESCE(ae.start_time, ae.end_time)
            AT TIME ZONE 'Europe/Amsterdam'
        )::date AS local_date,
        ae.start_time,
        ae.end_time,
        ae.value,
        ae.unit,
        NULLIF(
            ae.data #>> '{metadata,data_origin}',
            ''
        ) AS data_origin
    FROM health.activity_events AS ae
    WHERE ae.data_type IN (
        'steps',
        'distance',
        'active_calories'
    )
),
ranked AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (
            PARTITION BY b.data_type, b.local_date
            ORDER BY
                CASE
                    -- Missing origin is the Health Connect aggregate-style
                    -- snapshot currently emitted by the webhook.
                    WHEN b.data_origin IS NULL THEN 0
                    ELSE COALESCE(p.priority, 1000)
                END,
                b.end_time DESC NULLS LAST,
                b.id DESC
        ) AS rn
    FROM base AS b
    LEFT JOIN health.analytics_source_priority AS p
      ON p.data_type = b.data_type
     AND p.data_origin = b.data_origin
)
SELECT
    local_date,
    data_type,
    value,
    unit,
    start_time,
    end_time AS observed_through,
    data_origin
FROM ranked
WHERE rn = 1;


-- For relatively slow-changing body measurements, select one
-- authoritative writer per metric/day rather than plotting copies
-- propagated through several sync applications.
CREATE OR REPLACE VIEW health.body_measurements_daily AS
WITH base AS (
    SELECT
        m.id,
        m.data_type,
        (m.observed_at AT TIME ZONE 'Europe/Amsterdam')::date AS local_date,
        m.observed_at,
        m.value,
        m.unit,
        NULLIF(
            m.data #>> '{metadata,data_origin}',
            ''
        ) AS data_origin
    FROM health.measurements AS m
    WHERE m.data_type IN (
        'weight',
        'height',
        'body_fat'
    )
),
ranked AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (
            PARTITION BY b.data_type, b.local_date
            ORDER BY
                COALESCE(p.priority, 1000),
                b.observed_at DESC,
                b.id DESC
        ) AS rn
    FROM base AS b
    LEFT JOIN health.analytics_source_priority AS p
      ON p.data_type = b.data_type
     AND p.data_origin = b.data_origin
)
SELECT
    local_date,
    data_type,
    observed_at,
    value,
    unit,
    data_origin
FROM ranked
WHERE rn = 1;


CREATE OR REPLACE VIEW health.body_composition_preferred AS
SELECT
    w.local_date,
    w.observed_at,
    w.value AS weight_kilograms,
    h.value AS height_meters,
    CASE
        WHEN h.value > 0
        THEN ROUND(
            (w.value / (h.value * h.value))::numeric,
            2
        )
    END AS bmi,
    bf.value AS body_fat_percent,
    w.data_origin AS weight_data_origin,
    h.data_origin AS height_data_origin,
    bf.data_origin AS body_fat_data_origin
FROM health.body_measurements_daily AS w
LEFT JOIN LATERAL (
    SELECT h1.*
    FROM health.body_measurements_daily AS h1
    WHERE h1.data_type = 'height'
      AND h1.local_date <= w.local_date
    ORDER BY h1.local_date DESC, h1.observed_at DESC
    LIMIT 1
) AS h ON true
LEFT JOIN LATERAL (
    SELECT bf1.*
    FROM health.body_measurements_daily AS bf1
    WHERE bf1.data_type = 'body_fat'
      AND bf1.local_date <= w.local_date
    ORDER BY bf1.local_date DESC, bf1.observed_at DESC
    LIMIT 1
) AS bf ON true
WHERE w.data_type = 'weight';

-- END AUTHORITATIVE ANALYTICS V2
