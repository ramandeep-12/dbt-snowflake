{% macro generate_schema_name(custom_schema_name, node) -%}
    {#- Local/prod: bronze, silver, gold. CI: CI_BRONZE, CI_SILVER, CI_GOLD. -#}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif target.name == 'ci' -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}