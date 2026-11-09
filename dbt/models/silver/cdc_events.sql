-- Change data capture between consecutive published days: for each day, which stations
-- appeared (insert), disappeared (delete) or changed a price (update).
WITH days AS (
    SELECT price_date, lag(price_date) OVER (ORDER BY price_date) AS previous_date
    FROM (SELECT DISTINCT price_date FROM {{ ref('prices_daily') }})
),

today AS (  -- each station on the day being compared
    SELECT d.price_date AS change_date, p.station_id, p.price_gasoline_95, p.price_diesel
    FROM days AS d
    JOIN {{ ref('prices_daily') }} AS p ON p.price_date = d.price_date
    WHERE d.previous_date IS NOT NULL
),

yesterday AS (  -- each station on the previous published day, keyed by the day being compared
    SELECT d.price_date AS change_date, p.station_id, p.price_gasoline_95, p.price_diesel
    FROM days AS d
    JOIN {{ ref('prices_daily') }} AS p ON p.price_date = d.previous_date
)

SELECT
    coalesce(t.change_date, y.change_date) AS change_date,
    coalesce(t.station_id, y.station_id)   AS station_id,
    CASE
        WHEN y.station_id IS NULL THEN 'insert'
        WHEN t.station_id IS NULL THEN 'delete'
        ELSE 'update'
    END                                    AS change_type,
    y.price_gasoline_95 AS previous_gasoline_95, t.price_gasoline_95 AS gasoline_95,
    y.price_diesel      AS previous_diesel,      t.price_diesel      AS diesel
FROM today AS t
FULL OUTER JOIN yesterday AS y
    ON t.change_date = y.change_date AND t.station_id = y.station_id
WHERE y.station_id IS NULL
   OR t.station_id IS NULL
   OR t.price_gasoline_95 IS DISTINCT FROM y.price_gasoline_95
   OR t.price_diesel      IS DISTINCT FROM y.price_diesel
