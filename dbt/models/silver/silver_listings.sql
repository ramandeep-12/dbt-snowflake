{{ config(
    materialized = 'incremental',
    unique_key = 'listing_id'
) }}

select
    raw:listing_id::number                        as listing_id,
    raw:host_id::number                           as host_id,
    {{ trimmer("raw:property_type::varchar") }}   as property_type,
    raw:room_type::varchar                        as room_type,
    raw:accommodates::number                      as accommodates,
    raw:bedrooms::number                          as bedrooms,
    raw:address.city::varchar                     as city,
    raw:address.country::varchar                  as country,
    raw:bathrooms::number(4,1)                    as bathrooms,
    raw:price_per_night::number(10,2)             as price_per_night,
    {{ tag("cast(raw:price_per_night as int)") }} as price_per_night_tag,
    raw:created_at::timestamp_ntz                 as created_at
from {{ ref('listings') }}
{% if is_incremental() %}
where raw:created_at::timestamp_ntz > (select coalesce(max(created_at), '1900-01-01') from {{ this }})
{% endif %}