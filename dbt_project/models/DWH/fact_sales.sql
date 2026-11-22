{{ config(
    materialized='incremental',
    unique_key=['order_id', 'order_item_id'],
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

-- Grain: exactly one row per order line (order_id + order_item_id).
-- A 30-day overlap lets recently arriving/corrected orders be reprocessed.
WITH order_lines AS (
    SELECT
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.shipping_limit_date,
        oi.item_price,
        oi.freight_value,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM {{ ref('stg_order_items') }} AS oi
    INNER JOIN {{ ref('stg_orders') }} AS o
        ON oi.order_id = o.order_id
    {% if is_incremental() %}
    WHERE o.order_purchase_timestamp >= (
        SELECT COALESCE(MAX(order_purchase_timestamp), TIMESTAMP '1900-01-01')
        FROM {{ this }}
    ) - ({{ var('incremental_lookback_days', 30) }} * INTERVAL '1 day')
    {% endif %}
)
SELECT
    ol.order_id,
    ol.order_item_id,
    dc.customer_id,
    dp.product_id,
    ds.seller_id,
    dos.order_status,
    purchase_date.date_key AS purchase_date_key,
    approved_date.date_key AS approved_date_key,
    carrier_date.date_key AS delivered_carrier_date_key,
    delivered_date.date_key AS delivered_customer_date_key,
    estimated_date.date_key AS estimated_delivery_date_key,
    shipping_date.date_key AS shipping_limit_date_key,
    ol.order_purchase_timestamp,
    ol.item_price,
    ol.freight_value,
    ol.item_price + ol.freight_value AS item_total_amount,
    CASE
        WHEN ol.order_delivered_customer_date IS NOT NULL
        THEN CAST(ol.order_delivered_customer_date AS date) - CAST(ol.order_purchase_timestamp AS date)
        ELSE NULL
    END AS delivery_days,
    CASE
        WHEN ol.order_delivered_customer_date IS NOT NULL
         AND ol.order_estimated_delivery_date IS NOT NULL
        THEN CAST(ol.order_delivered_customer_date AS date) - ol.order_estimated_delivery_date
        ELSE NULL
    END AS delivery_delay_days
FROM order_lines AS ol
LEFT JOIN {{ ref('dim_customer') }} AS dc
    ON ol.customer_id = dc.customer_id
LEFT JOIN {{ ref('dim_product') }} AS dp
    ON ol.product_id = dp.product_id
LEFT JOIN {{ ref('dim_seller') }} AS ds
    ON ol.seller_id = ds.seller_id
LEFT JOIN {{ ref('dim_order_status') }} AS dos
    ON ol.order_status = dos.order_status
LEFT JOIN {{ ref('dim_date') }} AS purchase_date
    ON CAST(ol.order_purchase_timestamp AS date) = purchase_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS approved_date
    ON CAST(ol.order_approved_at AS date) = approved_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS carrier_date
    ON CAST(ol.order_delivered_carrier_date AS date) = carrier_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS delivered_date
    ON CAST(ol.order_delivered_customer_date AS date) = delivered_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS estimated_date
    ON ol.order_estimated_delivery_date = estimated_date.full_date
LEFT JOIN {{ ref('dim_date') }} AS shipping_date
    ON CAST(ol.shipping_limit_date AS date) = shipping_date.full_date