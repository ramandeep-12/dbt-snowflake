{{config(
    severity='warn',
)}}
select 1 from {{source('raw','bookings')}}
where booking_amount < 200