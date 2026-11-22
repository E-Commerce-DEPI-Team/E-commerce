SELECT
    LOWER({{ clean_text('order_id') }}) AS order_id,
    CAST({{ clean_text('payment_sequential') }} AS integer) AS payment_sequential,
    LOWER({{ clean_text('payment_type') }}) AS payment_type,
    CAST({{ clean_text('payment_installments') }} AS integer) AS payment_installments,
    CAST({{ clean_text('payment_value') }} AS numeric(18, 2)) AS payment_value
FROM {{ source('olist_staging', 'olist_order_payments_staging') }}