SELECT
    {{ clean_text('geolocation_zip_code_prefix') }} AS geolocation_zip_code_prefix,
    TRY_CONVERT(decimal(18, 14), geolocation_lat) AS geolocation_lat,
    TRY_CONVERT(decimal(18, 14), geolocation_lng) AS geolocation_lng,
    LOWER({{ clean_text('geolocation_city') }}) AS geolocation_city,
    UPPER({{ clean_text('geolocation_state') }}) AS geolocation_state
FROM {{ source('olist_staging', 'olist_geolocation_staging') }}
