-- Which day of the week is cheapest? Each day is compared with the centred 7-day moving
-- average around it (3 days before, 3 after). Comparing with the calendar week instead
-- would bias the result whenever prices trend: in a falling market every Monday looks
-- dearer than its Sunday. Only days with a full 7-day window are used.
WITH daily AS (
    SELECT price_date, avg(price_diesel) AS diesel, avg(price_gasoline_95) AS gasoline_95
    FROM {{ ref('prices_daily') }}
    GROUP BY price_date
),

detrended AS (
    SELECT
        price_date,
        isodow(price_date)              AS day_of_week,
        diesel - avg(diesel) OVER w           AS diesel_vs_trend,
        gasoline_95 - avg(gasoline_95) OVER w AS gasoline_95_vs_trend,
        count(*) OVER w                       AS window_days
    FROM daily
    WINDOW w AS (ORDER BY price_date ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING)
)

SELECT
    day_of_week,
    CASE day_of_week WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday'
                     WHEN 5 THEN 'Friday' WHEN 6 THEN 'Saturday' ELSE 'Sunday' END AS day_name,
    round(1000 * avg(diesel_vs_trend), 2)      AS diesel_vs_week_eur_per_1000l,
    round(1000 * avg(gasoline_95_vs_trend), 2) AS gasoline_95_vs_week_eur_per_1000l,
    count(*)                                   AS days
FROM detrended
WHERE window_days = 7
GROUP BY day_of_week
