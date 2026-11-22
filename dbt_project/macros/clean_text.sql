{% macro clean_text(column_name) -%}
    NULLIF(LTRIM(RTRIM({{ column_name }})), '')
{%- endmacro %}
