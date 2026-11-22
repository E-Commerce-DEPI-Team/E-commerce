{% macro clean_text(column_name) -%}
    NULLIF(TRIM(CAST({{ column_name }} AS text)), '')
{%- endmacro %}