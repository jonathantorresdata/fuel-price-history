-- Grain: one row per station and day.
SELECT *
FROM {{ ref('stg_station_prices') }}
WHERE station_id IS NOT NULL
QUALIFY row_number() OVER (PARTITION BY station_id, price_date ORDER BY _source_file DESC) = 1
