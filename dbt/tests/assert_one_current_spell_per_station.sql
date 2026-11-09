-- SCD2 rule: every station has exactly one open (current) version.
SELECT station_id FROM {{ ref('price_history_scd2') }}
GROUP BY station_id HAVING count(*) FILTER (WHERE is_current) <> 1
