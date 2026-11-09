-- SCD2 rule: versions of a station never overlap and leave no gap (valid_to + 1 = next valid_from).
SELECT station_id, valid_from
FROM (
    SELECT station_id, valid_from, valid_to,
           lead(valid_from) OVER (PARTITION BY station_id ORDER BY valid_from) AS next_from
    FROM {{ ref('price_history_scd2') }}
)
WHERE next_from IS NOT NULL AND valid_to + INTERVAL 1 DAY <> next_from
