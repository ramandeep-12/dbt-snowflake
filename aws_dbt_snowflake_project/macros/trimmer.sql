{% macro trimmer(column_name) %}
upper(TRIM({{column_name}}))
{% endmacro %}