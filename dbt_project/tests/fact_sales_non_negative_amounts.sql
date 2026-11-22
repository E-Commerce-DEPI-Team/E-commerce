SELECT *
FROM {{ ref('fact_sales') }}
WHERE item_price < 0
   OR freight_value < 0
   OR item_total_amount < 0
