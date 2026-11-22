{{ config(materialized='table') }}

-- Grain: one row per distinct order status.
SELECT DISTINCT
    order_status
FROM {{ ref('stg_orders') }}
WHERE order_status IS NOT NULL
