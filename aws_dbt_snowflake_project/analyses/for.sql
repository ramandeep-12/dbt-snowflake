{% set cols=['NIGHTS_BOOKED', 'booking_id', 'booking_amount'] %}

select
{% for col in cols %}
{{col}}
{% if not loop.last %},{% endif %}
{% endfor %}
from {{ref("bookings")}}
