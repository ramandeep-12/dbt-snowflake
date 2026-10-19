{{
    config(
        materialized='ephemeral'
    )
}}

with host as (
    select  host_id,
    host_name,
    is_superhost,
    response_rate_quality,
    host_created_at
    from {{ref('obt')}}
)
select * from host