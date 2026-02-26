{{ config(materialized='table') }}

with flights as (
    select * from {{ ref('prep_flights') }}
),
weather as (
    select * from {{ ref('prep_weather_daily') }}
),
airports as (
    select * from {{ ref('prep_airports') }}
),
departures as (
    select
        origin_airport_id as airport_id,
        flight_date,
        count(distinct destination_airport_id) as unique_departure_connections,
        count(*) as total_departures,
        count(case when cancelled = 1 then 1 end) as cancelled_departures,
        count(case when diverted = 1 then 1 end) as diverted_departures,
        count(case when cancelled = 0 and diverted = 0 then 1 end) as completed_departures,
        count(distinct airplane_id) as unique_airplanes_departed,
        count(distinct airline_id) as unique_airlines_departed
    from flights
    group by 1,2
),
arrivals as (
    select
        destination_airport_id as airport_id,
        flight_date,
        count(distinct origin_airport_id) as unique_arrival_connections,
        count(*) as total_arrivals,
        count(case when cancelled = 1 then 1 end) as cancelled_arrivals,
        count(case when diverted = 1 then 1 end) as diverted_arrivals,
        count(case when cancelled = 0 and diverted = 0 then 1 end) as completed_arrivals,
        count(distinct airplane_id) as unique_airplanes_arrived,
        count(distinct airline_id) as unique_airlines_arrived
    from flights
    group by 1,2
)
select
    a.airport_id,
    a.airport_name,
    a.city,
    a.country,
    d.flight_date,
    coalesce(d.unique_departure_connections,0) as unique_departure_connections,
    coalesce(ar.unique_arrival_connections,0) as unique_arrival_connections,
    coalesce(d.total_departures,0)+coalesce(ar.total_arrivals,0) as total_flights_planned,
    coalesce(d.cancelled_departures,0)+coalesce(ar.cancelled_arrivals,0) as total_cancelled,
    coalesce(d.diverted_departures,0)+coalesce(ar.diverted_arrivals,0) as total_diverted,
    coalesce(d.completed_departures,0)+coalesce(ar.completed_arrivals,0) as total_completed,
    ((coalesce(d.unique_airplanes_departed,0)+coalesce(ar.unique_airplanes_arrived,0))/2) as avg_unique_airplanes,
    ((coalesce(d.unique_airlines_departed,0)+coalesce(ar.unique_airlines_arrived,0))/2) as avg_unique_airlines,
    w.min_temperature,
    w.max_temperature,
    w.precipitation,
    w.snowfall,
    w.avg_wind_direction,
    w.avg_wind_speed,
    w.wind_peak_gust
from airports a
left join departures d on a.airport_id = d.airport_id and d.flight_date = w.date
left join arrivals ar on a.airport_id = ar.airport_id and ar.flight_date = w.date
left join weather w on a.airport_id = w.station_id and w.date = d.flight_date