/*
Проект: SQL-анализ поведения игроков и внутриигровых покупок
Учебная база: fantasy
Автор: Гуро Кирилл Михайлович

Цель проекта:
изучить влияние характеристик игроков и их игровых персонажей
на покупку внутриигровой валюты, а также оценить активность игроков
при совершении внутриигровых покупок.
*/

-- =============================================================
-- 1. Доля платящих пользователей по всем данным
-- =============================================================

SELECT
    COUNT(*) AS total_users,
    SUM(payer) AS total_payers,
    ROUND(AVG(payer::numeric) * 100, 2) AS payers_share_percent
FROM fantasy.users;


-- =============================================================
-- 2. Доля платящих пользователей в разрезе расы персонажа
-- =============================================================

SELECT
    r.race AS race_name,
    COUNT(*) AS total_players,
    COUNT(CASE WHEN u.payer = 1 THEN 1 END) AS paying_players,
    ROUND(COUNT(CASE WHEN u.payer = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS paying_players_ratio_percent
FROM fantasy.users AS u
JOIN fantasy.race AS r
    ON u.race_id = r.race_id
GROUP BY r.race
ORDER BY paying_players_ratio_percent DESC;


-- =============================================================
-- 3. Статистические показатели по суммам покупок
-- =============================================================

SELECT
    COUNT(*) AS total_purchases,
    SUM(amount) AS total_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount,
    ROUND(AVG(amount), 2) AS avg_amount,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
    ROUND(STDDEV(amount), 2) AS stddev_amount
FROM fantasy.events
WHERE amount IS NOT NULL;


-- =============================================================
-- 4. Аномальные покупки с нулевой суммой
-- =============================================================

SELECT
    COUNT(*) AS zero_amount_count,
    ROUND(COUNT(*) * 100.0 / NULLIF((
        SELECT COUNT(*)
        FROM fantasy.events
        WHERE amount IS NOT NULL
    ), 0), 2) AS zero_amount_ratio_percent
FROM fantasy.events
WHERE amount = 0;


-- =============================================================
-- 5. Популярные эпические предметы
-- =============================================================

WITH purchase_stats AS (
    SELECT
        COUNT(DISTINCT id) AS total_unique_buyers
    FROM fantasy.events
    WHERE amount > 0
      AND amount IS NOT NULL
),
item_popularity AS (
    SELECT
        i.game_items AS epic_item,
        COUNT(*) AS total_sales,
        COUNT(DISTINCT e.id) AS unique_buyers,
        (SELECT total_unique_buyers FROM purchase_stats) AS total_buyers
    FROM fantasy.events AS e
    JOIN fantasy.items AS i
        ON e.item_code = i.item_code
    WHERE e.amount > 0
      AND e.amount IS NOT NULL
    GROUP BY i.game_items
)
SELECT
    epic_item,
    total_sales,
    ROUND(total_sales * 100.0 / NULLIF((SELECT SUM(total_sales) FROM item_popularity), 0), 2) AS sales_ratio_percent,
    unique_buyers,
    ROUND(unique_buyers * 100.0 / NULLIF(total_buyers, 0), 2) AS buyers_ratio_percent
FROM item_popularity
ORDER BY buyers_ratio_percent DESC, total_sales DESC;


-- =============================================================
-- 6. Зависимость покупательской активности от расы персонажа
-- =============================================================

WITH race_purchase_stats AS (
    SELECT
        r.race_id,
        r.race AS race_name,
        COUNT(DISTINCT u.id) AS total_players,
        COUNT(DISTINCT CASE WHEN e.transaction_id IS NOT NULL THEN u.id END) AS players_with_purchases,
        COUNT(DISTINCT CASE WHEN u.payer = 1 AND e.transaction_id IS NOT NULL THEN u.id END) AS paying_players_with_purchases,
        COUNT(e.transaction_id) AS total_purchases,
        SUM(e.amount) AS total_amount_spent
    FROM fantasy.race AS r
    LEFT JOIN fantasy.users AS u
        ON r.race_id = u.race_id
    LEFT JOIN fantasy.events AS e
        ON u.id = e.id
       AND e.amount > 0
       AND e.amount IS NOT NULL
    GROUP BY r.race_id, r.race
)
SELECT
    race_name,
    total_players,
    players_with_purchases,
    ROUND(players_with_purchases * 100.0 / NULLIF(total_players, 0), 2) AS purchasing_players_ratio_percent,
    ROUND(paying_players_with_purchases * 100.0 / NULLIF(players_with_purchases, 0), 2) AS paying_among_purchasing_ratio_percent,
    ROUND(total_purchases * 1.0 / NULLIF(players_with_purchases, 0), 2) AS avg_purchases_per_buyer,
    ROUND(total_amount_spent / NULLIF(total_purchases, 0), 2) AS avg_purchase_amount,
    ROUND(total_amount_spent / NULLIF(players_with_purchases, 0), 2) AS avg_total_spent_per_buyer
FROM race_purchase_stats
ORDER BY avg_total_spent_per_buyer DESC;
