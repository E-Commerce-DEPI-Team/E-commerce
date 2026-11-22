{{ config(materialized='table') }}

-- Grain: one row per customer_id (the order-facing customer address identifier).
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM {{ ref('stg_customers') }}
