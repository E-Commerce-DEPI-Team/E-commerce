{{ config(
    materialized='incremental',
    unique_key=['order_id'],
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

-- Grain: exactly one row per order (order_id).
-- Order-level KPIs are calculated once per order here, so they are not repeated on every item
-- (fact_sales repeats delivery_days for each item of the same order).
-- A 30-day overlap (same var as the other facts) lets recently changed orders be reprocessed.
WITH order_rows AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM {{ ref('stg_orders') }} AS o
    {% if is_incremental() %}
    WHERE o.order_purchase_timestamp >= DATEADD(
        day,
        -{{ var('incremental_lookback_days', 30) }},
        (SELECT COALESCE(MAX(order_purchase_timestamp), CONVERT(datetime2(0), '1900-01-01')) FROM {{ this }})
    )
    {% endif %}
),
item_totals AS (
    SELECT
        order_id,
        COUNT(*) AS items_count,
        COUNT(DISTINCT seller_id) AS sellers_count,
        SUM(item_price) AS items_total_price,
        SUM(freight_value) AS freight_total
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),
payment_totals AS (
    SELECT
        order_id,
        COUNT(*) AS payments_count,
        SUM(payment_value) AS payment_total,
        MAX(payment_installments) AS max_installments
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),
latest_review AS (
    -- some orders have more than one review: keep the most recent one for the order-level KPI
    -- (all reviews are still available in fact_reviews)
    SELECT order_id, review_score
    FROM (
        SELECT
            order_id,
            review_score,
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY review_answer_timestamp DESC, review_id DESC
            ) AS review_recency_rank
        FROM {{ ref('stg_order_reviews') }}
    ) AS ranked_reviews
    WHERE review_recency_rank = 1
)
SELECT
    orr.order_id,
    dc.customer_id,
    dos.order_status,
    purchase_date.date_key AS purchase_date_key,
    delivered_date.date_key AS delivered_customer_date_key,
    estimated_date.date_key AS estimated_delivery_date_key,
    orr.order_purchase_timestamp,
    COALESCE(it.items_count, 0) AS items_count,
    COALESCE(it.sellers_count, 0) AS sellers_count,
    COALESCE(it.items_total_price, 0) AS items_total_price,
    COALESCE(it.freight_total, 0) AS freight_total,
    COALESCE(pt.payments_count, 0) AS payments_count,
    COALESCE(pt.payment_total, 0) AS payment_total,
    pt.max_installments,
    lr.review_score,
    CASE
        WHEN orr.order_approved_at IS NOT NULL
        THEN DATEDIFF(hour, orr.order_purchase_timestamp, orr.order_approved_at)
        ELSE NULL
    END AS approval_hours,
    CASE
        WHEN orr.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(day, CAST(orr.order_purchase_timestamp AS date), CAST(orr.order_delivered_customer_date AS date))
        ELSE NULL
    END AS delivery_days,
    CASE
        WHEN orr.order_delivered_customer_date IS NOT NULL
         AND orr.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(day, orr.order_estimated_delivery_date, CAST(orr.order_delivered_customer_date AS date))
        ELSE NULL
    END AS delivery_delay_days,
    CASE
        WHEN orr.order_delivered_customer_date IS NULL
          OR orr.order_estimated_delivery_date IS NULL THEN NULL
        WHEN CAST(orr.order_delivered_customer_date AS date) > orr.order_estimated_delivery_date THEN 1
        ELSE 0
    END AS is_late_delivery
FROM order_rows AS orr
LEFT JOIN item_totals AS it
    ON orr.order_id = it.order_id
LEFT JOIN payment_totals AS pt
    ON orr.order_id = pt.order_id
LEFT JOIN latest_review AS lr
    ON orr.order_id = lr.order_id
LEFT JOIN {{ ref('dim_customer') }} AS dc
    ON orr.customer_id = dc.customer_id
LEFT JOIN {{ ref('dim_order_status') }} AS dos
    ON orr.order_status = dos.order_status
LEFT JOIN {{ ref('dim_date') }} AS purchase_date
    ON CAST(orr.order_purchase_timestamp AS date) = purchase_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS delivered_date
    ON CAST(orr.order_delivered_customer_date AS date) = delivered_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS estimated_date
    ON orr.order_estimated_delivery_date = estimated_date.full_date
