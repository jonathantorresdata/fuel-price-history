-- SCD type 2: one row per station and price spell (period with the same prices).
-- Built with "gaps and islands": a new spell starts when either price differs from the
-- station's previous day; a running sum of those starts numbers the spells.
WITH flagged AS (
    SELECT
        station_id, price_date, price_gasoline_95, price_diesel,
        CASE
            WHEN lag(price_date) OVER w IS NULL THEN 1
            WHEN price_gasoline_95 IS DISTINCT FROM lag(price_gasoline_95) OVER w
              OR price_diesel      IS DISTINCT FROM lag(price_diesel) OVER w THEN 1
            ELSE 0
        END AS is_new_spell
    FROM {{ ref('prices_daily') }}
    WINDOW w AS (PARTITION BY station_id ORDER BY price_date)
),

spells AS (
    SELECT *, sum(is_new_spell) OVER (PARTITION BY station_id ORDER BY price_date) AS spell_number
    FROM flagged
),

collapsed AS (
    SELECT
        station_id,
        spell_number,
        min(price_date)            AS valid_from,
        max(price_date)            AS last_seen,
        any_value(price_gasoline_95) AS price_gasoline_95,
        any_value(price_diesel)      AS price_diesel,
        count(*)                   AS days_observed
    FROM spells
    GROUP BY station_id, spell_number
)

SELECT
    station_id,
    spell_number,
    price_gasoline_95,
    price_diesel,
    valid_from,
    lead(valid_from) OVER (PARTITION BY station_id ORDER BY valid_from) - INTERVAL 1 DAY AS valid_to,
    lead(valid_from) OVER (PARTITION BY station_id ORDER BY valid_from) IS NULL          AS is_current,
    days_observed
FROM collapsed
