-- Latest day: average price per province.
SELECT province, count(*) AS stations,
       round(avg(price_diesel), 3) AS diesel, round(avg(price_gasoline_95), 3) AS gasoline_95
FROM {{ ref('prices_daily') }}
WHERE price_date = (SELECT max(price_date) FROM {{ ref('prices_daily') }})
GROUP BY province
