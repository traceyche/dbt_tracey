{{ config(materialized='table') }}

with departures as (
    select
        origin as airport_code,
        count(distinct dest) as unique_departure_connections,
        count(*) as total_departures,
        count(case when cancelled = 1 then 1 end) as cancelled_departures,
        count(case when diverted = 1 then 1 end) as diverted_departures,
        count(case when cancelled = 0 and diverted = 0 then 1 end) as completed_departures,
        count(distinct tail_number) as unique_airplanes_departed,
        count(distinct airline) as unique_airlines_departed
    from {{ ref('prep_flights') }}
    group by origin
),

arrivals as (
    select
        dest as airport_code,
        count(distinct origin) as unique_arrival_connections,
        count(*) as total_arrivals,
        count(case when cancelled = 1 then 1 end) as cancelled_arrivals,
        count(case when diverted = 1 then 1 end) as diverted_arrivals,
        count(case when cancelled = 0 and diverted = 0 then 1 end) as completed_arrivals,
        count(distinct tail_number) as unique_airplanes_arrived,
        count(distinct airline) as unique_airlines_arrived
    from {{ ref('prep_flights') }}
    group by dest
)

select
    prep_airports.faa as airport_code,
    prep_airports.name as airport_name,
    prep_airports.city,
    prep_airports.country,
    coalesce(departures.unique_departure_connections,0) as unique_departure_connections,
    coalesce(arrivals.unique_arrival_connections,0) as unique_arrival_connections,
    coalesce(departures.total_departures,0) + coalesce(arrivals.total_arrivals,0) as total_flights_planned,
    coalesce(departures.cancelled_departures,0) + coalesce(arrivals.cancelled_arrivals,0) as total_cancelled,
    coalesce(departures.diverted_departures,0) + coalesce(arrivals.diverted_arrivals,0) as total_diverted,
    coalesce(departures.completed_departures,0) + coalesce(arrivals.completed_arrivals,0) as total_completed,
    ((coalesce(departures.unique_airplanes_departed,0) + coalesce(arrivals.unique_airplanes_arrived,0))/2) as avg_unique_airplanes,
    ((coalesce(departures.unique_airlines_departed,0) + coalesce(arrivals.unique_airlines_arrived,0))/2) as avg_unique_airlines
from {{ ref('prep_airports') }}
left join departures on prep_airports.faa = departures.airport_code
left join arrivals on prep_airports.faa = arrivals.airport_code