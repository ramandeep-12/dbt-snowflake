{{
    config(
        materialized='ephemeral'
    )
}}

with booking as (
    select  booking_id,
    booking_status,
    created_at
    from {{ref('obt')}}
)
select * from booking