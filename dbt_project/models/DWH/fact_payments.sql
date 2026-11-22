{{ config(
    materialized='incremental',
    unique_key=['order_id', 'payment_sequential'],
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

-- Grain: one row per payment record within an order (order_id + payment_sequential).
WITH payment_rows AS (
    SELECT
        p.order_id,
        p.payment_sequential,
        p.payment_type,
        p.payment_installments,
        p.payment_value,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp
    FROM {{ ref('stg_order_payments') }} AS p
    INNER JOIN {{ ref('stg_orders') }} AS o
        ON p.order_id = o.order_id
    {% if is_incremental() %}
    WHERE o.order_purchase_timestamp >= DATEADD(
        day,
        -{{ var('incremental_lookback_days', 30) }},
        (SELECT COALESCE(MAX(order_purchase_timestamp), CONVERT(datetime2(0), '1900-01-01')) FROM {{ this }})
    )
    {% endif %}
)
SELECT
    pr.order_id,
    pr.payment_sequential,
    dc.customer_id,
    dpt.payment_type,
    dos.order_status,
    dd.date_key AS purchase_date_key,
    pr.order_purchase_timestamp,
    pr.payment_installments,
    pr.payment_value
FROM payment_rows AS pr
LEFT JOIN {{ ref('dim_customer') }} AS dc
    ON pr.customer_id = dc.customer_id
LEFT JOIN {{ ref('dim_payment_type') }} AS dpt
    ON pr.payment_type = dpt.payment_type
LEFT JOIN {{ ref('dim_order_status') }} AS dos
    ON pr.order_status = dos.order_status
LEFT JOIN {{ ref('dim_date') }} AS dd
    ON CAST(pr.order_purchase_timestamp AS date) = dd.full_date
