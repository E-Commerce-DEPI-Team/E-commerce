SELECT
    LOWER({{ clean_text('p.product_id') }}) AS product_id,
    {{ clean_text('p.product_category_name') }} AS product_category_name,
    COALESCE(
        {{ clean_text('p.product_category_name_english') }},
        {{ clean_text('ct.product_category_name_english') }}
    ) AS product_category_name_english,
    CAST({{ clean_text('p.product_name_lenght') }} AS integer) AS product_name_length,
    CAST({{ clean_text('p.product_description_lenght') }} AS integer) AS product_description_length,
    CAST({{ clean_text('p.product_photos_qty') }} AS integer) AS product_photos_qty,
    CAST({{ clean_text('p.product_weight_g') }} AS numeric(12, 2)) AS product_weight_g,
    CAST({{ clean_text('p.product_length_cm') }} AS numeric(12, 2)) AS product_length_cm,
    CAST({{ clean_text('p.product_height_cm') }} AS numeric(12, 2)) AS product_height_cm,
    CAST({{ clean_text('p.product_width_cm') }} AS numeric(12, 2)) AS product_width_cm
FROM {{ source('olist_staging', 'olist_products_staging') }} AS p
LEFT JOIN {{ ref('stg_category_translation') }} AS ct
    ON {{ clean_text('p.product_category_name') }} = ct.product_category_name