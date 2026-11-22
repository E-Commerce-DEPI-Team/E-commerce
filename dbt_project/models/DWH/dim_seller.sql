{{ config(materialized='table') }}

-- Grain: one row per seller_id.
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM {{ ref('stg_sellers') }}
