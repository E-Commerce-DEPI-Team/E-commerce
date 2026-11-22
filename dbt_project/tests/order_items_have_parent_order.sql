SELECT oi.order_id, oi.order_item_id
FROM {{ ref('stg_order_items') }} AS oi
LEFT JOIN {{ ref('stg_orders') }} AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
