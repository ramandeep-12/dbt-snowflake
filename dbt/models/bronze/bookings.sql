{{ config(materialized='incremental') }}

select * from {{ source('raw', 'bookings') }}
{% if is_incremental() %}
where loaded_at > (select coalesce(max(loaded_at), '1900-01-01') from {{ this }})
{% endif %}