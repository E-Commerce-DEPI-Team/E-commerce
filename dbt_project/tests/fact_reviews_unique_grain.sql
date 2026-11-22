SELECT
    review_id,
    order_id,
    COUNT(*) AS row_count
FROM {{ ref('fact_reviews') }}
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1