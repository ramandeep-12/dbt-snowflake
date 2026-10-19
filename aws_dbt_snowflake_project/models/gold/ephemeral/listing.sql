{{
    config(
        materialized='ephemeral'
    )
}}

with listing as (
    select  listing_id,
    property_type,
    room_type,
    city,
    country,
    listing_created_at
    from {{ref('obt')}}
)
select * from listing