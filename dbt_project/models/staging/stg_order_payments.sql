SELECT
    LOWER({{ clean_text('order_id') }}) AS order_id,
    TRY_CONVERT(int, payment_sequential) AS payment_sequential,
    LOWER({{ clean_text('payment_type') }}) AS payment_type,
    TRY_CONVERT(int, payment_installments) AS payment_installments,
    TRY_CONVERT(decimal(18, 2), payment_value) AS payment_value
FROM {{ source('olist_staging', 'olist_order_payments_staging') }}
