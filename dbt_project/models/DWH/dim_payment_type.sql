{{ config(materialized='table') }}

-- Grain: one row per distinct payment type.
SELECT DISTINCT
    payment_type
FROM {{ ref('stg_order_payments') }}
WHERE payment_type IS NOT NULL
