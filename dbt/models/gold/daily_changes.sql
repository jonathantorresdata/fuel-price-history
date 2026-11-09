-- How much the market moves: per day, stations that opened, closed or changed a price.
SELECT
    c.change_date,
    count(*) FILTER (WHERE change_type = 'insert') AS opened,
    count(*) FILTER (WHERE change_type = 'delete') AS closed,
    count(*) FILTER (WHERE change_type = 'update') AS price_changes,
    round(100.0 * count(*) FILTER (WHERE change_type = 'update') / any_value(s.stations), 1) AS pct_stations_changing
FROM {{ ref('cdc_events') }} AS c
JOIN (SELECT price_date, count(*) AS stations FROM {{ ref('prices_daily') }} GROUP BY price_date) AS s
    ON s.price_date = c.change_date
GROUP BY c.change_date
