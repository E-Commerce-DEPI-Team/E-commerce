SELECT
    LOWER({{ clean_text('p.product_id') }}) AS product_id,
    {{ clean_text('p.product_category_name') }} AS product_category_name,
    COALESCE(
        {{ clean_text('p.product_category_name_english') }},
        {{ clean_text('ct.product_category_name_english') }}
    ) AS product_category_name_english,
    TRY_CONVERT(int, p.product_name_lenght) AS product_name_length,
    TRY_CONVERT(int, p.product_description_lenght) AS product_description_length,
    TRY_CONVERT(int, p.product_photos_qty) AS product_photos_qty,
    TRY_CONVERT(decimal(12, 2), p.product_weight_g) AS product_weight_g,
    TRY_CONVERT(decimal(12, 2), p.product_length_cm) AS product_length_cm,
    TRY_CONVERT(decimal(12, 2), p.product_height_cm) AS product_height_cm,
    TRY_CONVERT(decimal(12, 2), p.product_width_cm) AS product_width_cm
FROM {{ source('olist_staging', 'olist_products_staging') }} AS p
LEFT JOIN {{ ref('stg_category_translation') }} AS ct
    ON {{ clean_text('p.product_category_name') }} = ct.product_category_name
