SELECT
    LOWER({{ clean_text('order_id') }}) AS order_id,
    TRY_CONVERT(int, order_item_id) AS order_item_id,
    LOWER({{ clean_text('product_id') }}) AS product_id,
    LOWER({{ clean_text('seller_id') }}) AS seller_id,
    TRY_CONVERT(datetime2(0), shipping_limit_date) AS shipping_limit_date,
    TRY_CONVERT(decimal(18, 2), price) AS item_price,
    TRY_CONVERT(decimal(18, 2), freight_value) AS freight_value
FROM {{ source('olist_staging', 'olist_order_items_staging') }}
