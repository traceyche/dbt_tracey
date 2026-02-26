{{ config(materialized='table') }}

with route_stats as (
    select
        origin as origin_airport_code,
        dest as destination_airport_code,
        count(*) as total_flights,
        count(distinct tail_number) as unique_airplanes,
        count(distinct airline) as unique_airlines,
        avg(actual_elapsed_time) as avg_actual_elapsed_time,
        avg(arr_delay) as avg_arrival_delay,
        max(arr_delay) as max_arrival_delay,
        min(arr_delay) as min_arrival_delay,
        sum(case when cancelled = 1 then 1 else 0 end) as total_cancelled,
        sum(case when diverted = 1 then 1 else 0 end) as total_diverted
    from {{ ref('prep_flights') }}
    group by origin, dest
)

select
    route_stats.origin_airport_code,
    route_stats.destination_airport_code,
    route_stats.total_flights,
    route_stats.unique_airplanes,
    route_stats.unique_airlines,
    route_stats.avg_actual_elapsed_time,
    route_stats.avg_arrival_delay,
    route_stats.max_arrival_delay,
    route_stats.min_arrival_delay,
    route_stats.total_cancelled,
    route_stats.total_diverted,
    prep_airports_origin.name as origin_airport_name,
    prep_airports_origin.city as origin_city,
    prep_airports_origin.country as origin_country,
    prep_airports_destination.name as destination_airport_name,
    prep_airports_destination.city as destination_city,
    prep_airports_destination.country as destination_country
from route_stats
left join {{ ref('prep_airports') }} prep_airports_origin
    on route_stats.origin_airport_code = prep_airports_origin.faa
left join {{ ref('prep_airports') }} prep_airports_destination
    on route_stats.destination_airport_code = prep_airports_destination.faa