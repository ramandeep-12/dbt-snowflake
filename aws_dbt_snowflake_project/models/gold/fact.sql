{%
    set configs=[
        {
            "table": ref('obt'),
            "columns": "gold_obt.booking_id, gold_obt.host_id,gold_obt.listing_id ,gold_obt.total_amount, gold_obt.service_fee, gold_obt.cleaning_fee, gold_obt.accommodates, gold_obt.bedrooms, gold_obt.bathrooms, gold_obt.price_per_night, gold_obt.response_rate",
            "alias": "Gold_obt"
        }
    ]
%}


select 
    {{configs[0]['columns']}} from 
{{configs[0]['table']}} as {{configs[0]['alias']}}
