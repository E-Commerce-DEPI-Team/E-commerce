SELECT
    LOWER({{ clean_text('customer_id') }}) AS customer_id,
    LOWER({{ clean_text('customer_unique_id') }}) AS customer_unique_id,
    {{ clean_text('customer_zip_code_prefix') }} AS customer_zip_code_prefix,
    LOWER({{ clean_text('customer_city') }}) AS customer_city,
    UPPER({{ clean_text('customer_state') }}) AS customer_state
FROM {{ source('olist_staging', 'olist_customers_staging') }}
