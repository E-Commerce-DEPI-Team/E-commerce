SELECT
    {{ clean_text('product_category_name') }} AS product_category_name,
    {{ clean_text('product_category_name_english') }} AS product_category_name_english
FROM {{ source('olist_staging', 'olist_category_translation_staging') }}
