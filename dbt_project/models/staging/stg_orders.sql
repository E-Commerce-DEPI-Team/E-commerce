SELECT
    LOWER({{ clean_text('order_id') }}) AS order_id,
    LOWER({{ clean_text('customer_id') }}) AS customer_id,
    LOWER({{ clean_text('order_status') }}) AS order_status,
    CAST({{ clean_text('order_purchase_timestamp') }} AS timestamp(0)) AS order_purchase_timestamp,
    CAST({{ clean_text('order_approved_at') }} AS timestamp(0)) AS order_approved_at,
    CAST({{ clean_text('order_delivered_carrier_date') }} AS timestamp(0)) AS order_delivered_carrier_date,
    CAST({{ clean_text('order_delivered_customer_date') }} AS timestamp(0)) AS order_delivered_customer_date,
    CAST({{ clean_text('order_estimated_delivery_date') }} AS date) AS order_estimated_delivery_date
FROM {{ source('olist_staging', 'olist_orders_staging') }}