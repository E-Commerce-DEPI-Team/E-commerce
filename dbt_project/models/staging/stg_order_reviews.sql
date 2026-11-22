SELECT
    LOWER({{ clean_text('review_id') }}) AS review_id,
    LOWER({{ clean_text('order_id') }}) AS order_id,
    CAST({{ clean_text('review_score') }} AS integer) AS review_score,
    {{ clean_text('review_comment_title') }} AS review_comment_title,
    {{ clean_text('review_comment_message') }} AS review_comment_message,
    CAST({{ clean_text('review_creation_date') }} AS timestamp(0)) AS review_creation_date,
    CAST({{ clean_text('review_answer_timestamp') }} AS timestamp(0)) AS review_answer_timestamp
FROM {{ source('olist_staging', 'olist_order_reviews_staging') }}