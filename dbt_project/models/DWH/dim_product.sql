{{ config(materialized='table') }}

-- Grain: one row per product_id.
-- Missing English category (no translation / no category) is shown as 'unknown' here in the
-- presentation layer; stg_products still keeps the original NULL.
SELECT
    product_id,
    product_category_name,
    COALESCE(product_category_name_english, 'unknown') AS product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ ref('stg_products') }}
