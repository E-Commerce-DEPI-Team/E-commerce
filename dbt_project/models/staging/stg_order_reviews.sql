SELECT
    LOWER({{ clean_text('review_id') }}) AS review_id,
    LOWER({{ clean_text('order_id') }}) AS order_id,
    TRY_CONVERT(int, review_score) AS review_score,
    {{ clean_text('review_comment_title') }} AS review_comment_title,
    {{ clean_text('review_comment_message') }} AS review_comment_message,
    TRY_CONVERT(datetime2(0), review_creation_date) AS review_creation_date,
    TRY_CONVERT(datetime2(0), review_answer_timestamp) AS review_answer_timestamp
FROM {{ source('olist_staging', 'olist_order_reviews_staging') }}
