{{ config(materialized='incremental') }}

select raw, file_name, loaded_at from {{ source('raw', 'listings_json') }}
{% if is_incremental() %}
where loaded_at > (select coalesce(max(loaded_at), '1900-01-01') from {{ this }})
{% endif %}