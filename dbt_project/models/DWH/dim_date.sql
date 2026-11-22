{{ config(materialized='table') }}

-- Grain: one row per calendar date, continuous (no gaps) from the first to the last date
-- that appears in any Olist order, shipping or review event.
WITH all_dates AS (
    SELECT CAST(order_purchase_timestamp AS date) AS full_date
    FROM {{ ref('stg_orders') }}
    WHERE order_purchase_timestamp IS NOT NULL

    UNION

    SELECT CAST(order_approved_at AS date)
    FROM {{ ref('stg_orders') }}
    WHERE order_approved_at IS NOT NULL

    UNION

    SELECT CAST(order_delivered_carrier_date AS date)
    FROM {{ ref('stg_orders') }}
    WHERE order_delivered_carrier_date IS NOT NULL

    UNION

    SELECT CAST(order_delivered_customer_date AS date)
    FROM {{ ref('stg_orders') }}
    WHERE order_delivered_customer_date IS NOT NULL

    UNION

    SELECT CAST(order_estimated_delivery_date AS date)
    FROM {{ ref('stg_orders') }}
    WHERE order_estimated_delivery_date IS NOT NULL

    UNION

    SELECT CAST(shipping_limit_date AS date)
    FROM {{ ref('stg_order_items') }}
    WHERE shipping_limit_date IS NOT NULL

    UNION

    SELECT CAST(review_creation_date AS date)
    FROM {{ ref('stg_order_reviews') }}
    WHERE review_creation_date IS NOT NULL

    UNION

    SELECT CAST(review_answer_timestamp AS date)
    FROM {{ ref('stg_order_reviews') }}
    WHERE review_answer_timestamp IS NOT NULL
),
bounds AS (
    SELECT
        MIN(full_date) AS start_date,
        MAX(full_date) AS end_date
    FROM all_dates
),
calendar AS (
    -- PostgreSQL has generate_series, so no helper "numbers" table is needed.
    SELECT CAST(gs AS date) AS full_date
    FROM bounds AS b
    CROSS JOIN LATERAL generate_series(
        CAST(b.start_date AS timestamp),
        CAST(b.end_date AS timestamp),
        INTERVAL '1 day'
    ) AS gs
),
calendar_parts AS (
    SELECT
        full_date,
        -- 0 = Monday ... 6 = Sunday (1900-01-01 was a Monday)
        (full_date - DATE '1900-01-01') % 7 AS weekday_number
    FROM calendar
)
SELECT
    CAST(to_char(full_date, 'YYYYMMDD') AS integer) AS date_key,
    full_date,
    CAST(EXTRACT(year FROM full_date) AS integer) AS calendar_year,
    CAST(EXTRACT(quarter FROM full_date) AS integer) AS calendar_quarter,
    CAST(EXTRACT(month FROM full_date) AS integer) AS calendar_month,
    CAST(EXTRACT(day FROM full_date) AS integer) AS day_of_month,
    CASE CAST(EXTRACT(month FROM full_date) AS integer)
        WHEN 1 THEN 'January'   WHEN 2 THEN 'February' WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'     WHEN 5 THEN 'May'      WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'      WHEN 8 THEN 'August'   WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'  WHEN 11 THEN 'November' ELSE 'December'
    END AS month_name,
    CASE weekday_number
        WHEN 0 THEN 'Monday'   WHEN 1 THEN 'Tuesday'  WHEN 2 THEN 'Wednesday'
        WHEN 3 THEN 'Thursday' WHEN 4 THEN 'Friday'   WHEN 5 THEN 'Saturday'
        ELSE 'Sunday'
    END AS day_name,
    CASE WHEN weekday_number IN (5, 6) THEN 1 ELSE 0 END AS is_weekend
FROM calendar_parts