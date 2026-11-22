SELECT
    LOWER({{ clean_text('order_id') }}) AS order_id,
    CAST({{ clean_text('order_item_id') }} AS integer) AS order_item_id,
    LOWER({{ clean_text('product_id') }}) AS product_id,
    LOWER({{ clean_text('seller_id') }}) AS seller_id,
    CAST({{ clean_text('shipping_limit_date') }} AS timestamp(0)) AS shipping_limit_date,
    CAST({{ clean_text('price') }} AS numeric(18, 2)) AS item_price,
    CAST({{ clean_text('freight_value') }} AS numeric(18, 2)) AS freight_value
FROM {{ source('olist_staging', 'olist_order_items_staging') }}