SELECT
    {{ clean_text('geolocation_zip_code_prefix') }} AS geolocation_zip_code_prefix,
    CAST({{ clean_text('geolocation_lat') }} AS numeric(18, 14)) AS geolocation_lat,
    CAST({{ clean_text('geolocation_lng') }} AS numeric(18, 14)) AS geolocation_lng,
    LOWER({{ clean_text('geolocation_city') }}) AS geolocation_city,
    UPPER({{ clean_text('geolocation_state') }}) AS geolocation_state
FROM {{ source('olist_staging', 'olist_geolocation_staging') }}