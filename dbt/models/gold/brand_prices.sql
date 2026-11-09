-- Latest day: average price per brand, for brands with at least 100 stations.
WITH latest AS (
    SELECT * FROM {{ ref('prices_daily') }}
    WHERE price_date = (SELECT max(price_date) FROM {{ ref('prices_daily') }})
)
SELECT brand, count(*) AS stations,
       round(avg(price_diesel), 3) AS diesel, round(avg(price_gasoline_95), 3) AS gasoline_95
FROM latest
GROUP BY brand
HAVING count(*) >= 100
