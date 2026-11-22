SELECT r.review_id, r.order_id
FROM {{ ref('stg_order_reviews') }} AS r
LEFT JOIN {{ ref('stg_orders') }} AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL
