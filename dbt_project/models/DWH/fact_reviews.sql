{{ config(
    materialized='incremental',
    unique_key=['review_id', 'order_id'],
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

-- Grain: one row per review_id + order_id. Reviews are not joined into fact_sales,
-- because a review is a separate business event and can multiply order lines.
WITH review_rows AS (
    SELECT
        r.review_id,
        r.order_id,
        r.review_score,
        r.review_comment_title,
        r.review_comment_message,
        r.review_creation_date,
        r.review_answer_timestamp,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp
    FROM {{ ref('stg_order_reviews') }} AS r
    INNER JOIN {{ ref('stg_orders') }} AS o
        ON r.order_id = o.order_id
    {% if is_incremental() %}
    WHERE r.review_creation_date >= DATEADD(
        day,
        -{{ var('incremental_lookback_days', 30) }},
        (SELECT COALESCE(MAX(review_creation_date), CONVERT(datetime2(0), '1900-01-01')) FROM {{ this }})
    )
    {% endif %}
)
SELECT
    rr.review_id,
    rr.order_id,
    dc.customer_id,
    dos.order_status,
    purchase_date.date_key AS purchase_date_key,
    review_date.date_key AS review_date_key,
    answer_date.date_key AS review_answer_date_key,
    rr.order_purchase_timestamp,
    rr.review_creation_date,
    rr.review_answer_timestamp,
    rr.review_score,
    rr.review_comment_title,
    rr.review_comment_message
FROM review_rows AS rr
LEFT JOIN {{ ref('dim_customer') }} AS dc
    ON rr.customer_id = dc.customer_id
LEFT JOIN {{ ref('dim_order_status') }} AS dos
    ON rr.order_status = dos.order_status
LEFT JOIN {{ ref('dim_date') }} AS purchase_date
    ON CAST(rr.order_purchase_timestamp AS date) = purchase_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS review_date
    ON CAST(rr.review_creation_date AS date) = review_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS answer_date
    ON CAST(rr.review_answer_timestamp AS date) = answer_date.full_date
