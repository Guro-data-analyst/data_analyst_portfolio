/*
DataLens-дашборд: аналитика рынка недвижимости
SQL-запросы, извлечённые из DataLens-экспорта.
*/

-- =============================================================
-- 1. DA - Новый QL-чарт
-- =============================================================
WITH city_stats AS (
    SELECT
        c.city,
        AVG(a.days_exposition) as avg_days_on_market,
        COUNT(a.id) as total_ads,
        DENSE_RANK() OVER (ORDER BY AVG(a.days_exposition) ASC) as dense_rank
    FROM
        real_estate.advertisement as a
        JOIN real_estate.flats f ON a.id = f.id
        JOIN real_estate.city c ON f.city_id = c.city_id
    WHERE
        a.days_exposition IS NOT NULL
        AND a.days_exposition > 0
    GROUP BY
        c.city
    HAVING
        COUNT(a.id) >= 5
)
SELECT
    city,
    avg_days_on_market,
    total_ads,
    dense_rank as position
FROM
    city_stats
WHERE
    dense_rank <= 5
ORDER BY avg_days_on_market;

