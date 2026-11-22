SELECT p.order_id, p.payment_sequential
FROM {{ ref('stg_order_payments') }} AS p
LEFT JOIN {{ ref('stg_orders') }} AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL
