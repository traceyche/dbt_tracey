{{ config(materialized='table') }}

with flights as (
    select * from {{ ref('prep_flights') }}  -- or staging_flights_one_month
),
airports as (
    select * from {{ ref('prep_airports') }}
)
select
    f.origin_airport_id,
    o.airport_name as origin_airport_name,
    o.city as origin_city,
    o.country as origin_country,
    f.destination_airport_id,
    d.airport_name as destination_airport_name,
    d.city as destination_city,
    d.country as destination_country,
    count(*) as total_flights,
    count(distinct f.airplane_id) as unique_airplanes,
    count(distinct f.airline_id) as unique_airlines,
    avg(f.actual_elapsed_time) as avg_actual_elapsed_time,
    avg(f.arrival_delay) as avg_arrival_delay,
    max(f.arrival_delay) as max_arrival_delay,
    min(f.arrival_delay) as min_arrival_delay,
    count(case when f.cancelled = 1 then 1 end) as total_cancelled,
    count(case when f.diverted = 1 then 1 end) as total_diverted
from flights f
left join airports o on f.origin_airport_id = o.airport_id
left join airports d on f.destination_airport_id = d.airport_id
group by 1,2,3,4,5,6,7,8