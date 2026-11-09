-- CDC must explain the station count: today = yesterday + opened - closed.
WITH counts AS (
    SELECT price_date, count(*) AS stations, lag(count(*)) OVER (ORDER BY price_date) AS previous
    FROM {{ ref('prices_daily') }} GROUP BY price_date
)
SELECT c.price_date
FROM counts AS c
JOIN {{ ref('daily_changes') }} AS d ON d.change_date = c.price_date
WHERE c.stations <> c.previous + d.opened - d.closed
