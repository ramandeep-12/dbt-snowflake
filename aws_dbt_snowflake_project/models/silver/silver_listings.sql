{{ config (
    materialized = 'incremental',
    unique_key = 'listing_id'
)
}}

select listing_id,
host_id,
{{trimmer('property_type')}} as property_type,
room_type,
accommodates,
bedrooms,
city, 
country,
bathrooms,
price_per_night,
{{tag('cast(price_per_night as int)')}} as price_per_night_tag,
created_at
from {{ref('listings')}}