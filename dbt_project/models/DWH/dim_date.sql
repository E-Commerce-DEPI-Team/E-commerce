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
numbers AS (
    -- Counter 0,1,2,... taken from the rows of stg_orders (99k rows >> ~1,300 days needed).
    SELECT ROW_NUMBER() OVER (ORDER BY order_id) - 1 AS n
    FROM {{ ref('stg_orders') }}
),
calendar AS (
    SELECT DATEADD(day, CAST(n.n AS int), b.start_date) AS full_date
    FROM numbers AS n
    CROSS JOIN bounds AS b
    WHERE n.n <= DATEDIFF(day, b.start_date, b.end_date)
),
calendar_parts AS (
    SELECT
        full_date,
        -- 0 = Monday ... 6 = Sunday (1900-01-01 was a Monday); independent of SQL Server language/DATEFIRST
        DATEDIFF(day, CAST('1900-01-01' AS date), full_date) % 7 AS weekday_number
    FROM calendar
)
SELECT
    CONVERT(int, CONVERT(char(8), full_date, 112)) AS date_key,
    full_date,
    DATEPART(year, full_date) AS calendar_year,
    DATEPART(quarter, full_date) AS calendar_quarter,
    DATEPART(month, full_date) AS calendar_month,
    DATEPART(day, full_date) AS day_of_month,
    CASE DATEPART(month, full_date)
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
