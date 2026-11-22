SELECT
    LOWER({{ clean_text('seller_id') }}) AS seller_id,
    {{ clean_text('seller_zip_code_prefix') }} AS seller_zip_code_prefix,
    LOWER({{ clean_text('seller_city') }}) AS seller_city,
    UPPER({{ clean_text('seller_state') }}) AS seller_state
FROM {{ source('olist_staging', 'olist_sellers_staging') }}
