{{ config(materialized='table') }}
with departures as (
    select
        origin as airport_code,
        flight_date,
        count(distinct dest) as unique_departure_connections,
        count(*) as total_departures,
        count(case when cancelled = 1 then 1 end) as cancelled_departures,
        count(case when diverted = 1 then 1 end) as diverted_departures,
        count(case when cancelled = 0 and diverted = 0 then 1 end) as completed_departures,
        count(distinct tail_number) as unique_airplanes_departed,
        count(distinct airline) as unique_airlines_departed
    from {{ ref('prep_flights') }}
    group by origin, flight_date
),
arrivals as (
    select
        dest as airport_code,
        flight_date,
        count(distinct origin) as unique_arrival_connections,
        count(*) as total_arrivals,
        count(case when cancelled = 1 then 1 end) as cancelled_arrivals,
        count(case when diverted = 1 then 1 end) as diverted_arrivals,
        count(case when cancelled = 0 and diverted = 0 then 1 end) as completed_arrivals,
        count(distinct tail_number) as unique_airplanes_arrived,
        count(distinct airline) as unique_airlines_arrived
    from {{ ref('prep_flights') }}
    group by dest, flight_date
),
weather as (
    select * from {{ ref('prep_weather_daily') }}
)

select
    airport_code,
    airport_name,
    city,
    country,
    coalesce(departures.flight_date, arrivals.flight_date, weather.date) as flight_date,
    coalesce(unique_departure_connections,0) as unique_departure_connections,
    coalesce(unique_arrival_connections,0) as unique_arrival_connections,
    coalesce(total_departures,0) + coalesce(total_arrivals,0) as total_flights_planned,
    coalesce(cancelled_departures,0) + coalesce(cancelled_arrivals,0) as total_cancelled,
    coalesce(diverted_departures,0) + coalesce(diverted_arrivals,0) as total_diverted,
    coalesce(completed_departures,0) + coalesce(completed_arrivals,0) as total_completed,
    ((coalesce(unique_airplanes_departed,0) + coalesce(unique_airplanes_arrived,0))/2) as avg_unique_airplanes,
    ((coalesce(unique_airlines_departed,0) + coalesce(unique_airlines_arrived,0))/2) as avg_unique_airlines,
    min_temp_c,
    max_temp_c,
    avg_temp_c,
    precipitation_mm,
    max_snow_mm,
    avg_wind_direction,
    avg_wind_speed_kmh,
    wind_peakgust_kmh
from {{ ref('prep_airports') }}
left join departures on airport_code = departures.airport_code
left join arrivals on airport_code = arrivals.airport_code and arrivals.flight_date = departures.flight_date
left join weather on airport_code = weather.airport_code and weather.date = coalesce(departures.flight_date, arrivals.flight_date)