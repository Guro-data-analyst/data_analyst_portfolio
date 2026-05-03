/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Гуро Кирилл Михайлович
 * Дата: 08.11.2025
*/



-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
-- Шаг 1: Фильтрация аномальных значений
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
categorized_ads AS (
    SELECT 
        a.id,
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.rooms,
        f.balcony,
        f.floors_total,
        c.city,
        t.type,  -- Добавляем тип населенного пункта
        CASE 
            WHEN c.city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            WHEN t.type = 'город' THEN 'ЛенОбл'  -- Только города Ленобласти
            ELSE 'other'  -- Исключаем малые населенные пункты
        END AS region,
        CASE 
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN 'до месяца'
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN 'до трех месяцев'
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN 'до полугода'
            WHEN a.days_exposition > 180 THEN 'более полугода'
            ELSE 'non category'
        END AS activity_segment,
        CASE 
            WHEN f.total_area > 0 AND a.last_price > 0 
            THEN a.last_price / f.total_area 
            ELSE NULL 
        END AS price_per_m2
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    JOIN real_estate.type t ON f.type_id = t.type_id  -- Добавляем JOIN с таблицей типов
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
      AND f.total_area > 0 
      AND a.last_price > 0
      AND a.days_exposition IS NOT NULL
)
SELECT 
    region AS "Регион",
    activity_segment AS "Сегмент активности",
    COUNT(*) AS "Количество объектов",  -- Добавляем количество объектов
    ROUND(AVG(price_per_m2)::numeric, 2) AS "Средняя стоимость кв. метра",
    ROUND(AVG(total_area)::numeric, 2) AS "Средняя площадь",
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms) AS "Медиана кол-ва комнат",
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony) AS "Медиана кол-ва балконов",
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floors_total) AS "Медиана этажности"
FROM categorized_ads
WHERE activity_segment != 'non category'
  AND region != 'other'  -- Исключаем малые населенные пункты
GROUP BY region, activity_segment
ORDER BY 
    region,
    CASE activity_segment
        WHEN 'до месяца' THEN 1
        WHEN 'до трех месяцев' THEN 2
        WHEN 'до полугода' THEN 3
        WHEN 'более полугода' THEN 4
        ELSE 5
    END;


-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS (
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
-- Основные данные с датами публикации и снятия
ads_data AS (
    SELECT 
        a.id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        f.total_area,
        c.city,
        t.type,
        -- Дата снятия объявления
        a.first_day_exposition + INTERVAL '1 day' * a.days_exposition AS removal_date,
        -- Месяц публикации
        EXTRACT(MONTH FROM a.first_day_exposition) AS publication_month,
        -- Месяц снятия
        EXTRACT(MONTH FROM a.first_day_exposition + INTERVAL '1 day' * a.days_exposition) AS removal_month,
        -- Год
        EXTRACT(YEAR FROM a.first_day_exposition) AS year,
        -- Стоимость м²
        a.last_price / NULLIF(f.total_area, 0) AS price_per_m2
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    JOIN real_estate.type t ON f.type_id = t.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
      AND t.type = 'город'
      AND a.days_exposition IS NOT NULL
      AND f.total_area > 0
      AND a.last_price > 0
),
-- Статистика по месяцам публикации
publication_stats AS (
    SELECT 
        publication_month AS month,
        'publication' AS period_type,
        COUNT(*) AS ads_count,
        ROUND(AVG(price_per_m2)::numeric, 2) AS avg_price_per_m2,
        ROUND(AVG(total_area)::numeric, 2) AS avg_total_area,
        ROUND(AVG(last_price)::numeric, 2) AS avg_price
    FROM ads_data
    GROUP BY publication_month
),
-- Статистика по месяцам снятия объявлений
removal_stats AS (
    SELECT 
        removal_month AS month,
        'removal' AS period_type,
        COUNT(*) AS ads_count,
        ROUND(AVG(price_per_m2)::numeric, 2) AS avg_price_per_m2,
        ROUND(AVG(total_area)::numeric, 2) AS avg_total_area,
        ROUND(AVG(last_price)::numeric, 2) AS avg_price
    FROM ads_data
    WHERE removal_date IS NOT NULL
    GROUP BY removal_month
),
-- Объединенная статистика
combined_stats AS (
    SELECT * FROM publication_stats
    UNION ALL
    SELECT * FROM removal_stats
)
-- Итоговый результат
SELECT 
    month,
    period_type AS "Тип периода",
    ads_count AS "Количество объявлений",
    avg_price_per_m2 AS "Средняя цена м²",
    avg_total_area AS "Средняя площадь",
    avg_price AS "Средняя цена",
    ROUND(ads_count * 100.0 / SUM(ads_count) OVER (PARTITION BY period_type), 2) AS "Доля в периоде, %"
FROM combined_stats
ORDER BY period_type, month;