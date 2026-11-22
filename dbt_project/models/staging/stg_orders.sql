SELECT
    LOWER({{ clean_text('order_id') }}) AS order_id,
    LOWER({{ clean_text('customer_id') }}) AS customer_id,
    LOWER({{ clean_text('order_status') }}) AS order_status,
    TRY_CONVERT(datetime2(0), order_purchase_timestamp) AS order_purchase_timestamp,
    TRY_CONVERT(datetime2(0), order_approved_at) AS order_approved_at,
    TRY_CONVERT(datetime2(0), order_delivered_carrier_date) AS order_delivered_carrier_date,
    TRY_CONVERT(datetime2(0), order_delivered_customer_date) AS order_delivered_customer_date,
    TRY_CONVERT(date, order_estimated_delivery_date) AS order_estimated_delivery_date
FROM {{ source('olist_staging', 'olist_orders_staging') }}
