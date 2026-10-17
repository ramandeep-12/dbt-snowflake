{% set flag = 3 %}
{% set books = 1 %}
select * from {{ref('bookings')}} 
{% if flag == 1 %}
where nights_booked > {{books}}
{% else %}
where nights_booked = {{books}}
{% endif %}