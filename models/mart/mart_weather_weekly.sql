{{ config(materialized='table') }}

with daily as (
    select * from {{ ref('prep_weather_daily') }}
)

select
    station_id,
    date_trunc('week', date) as week_start,
    avg(avg_temp_c) as avg_weekly_temperature,
    max(max_temp_c) as max_weekly_temperature,
    min(min_temp_c) as min_weekly_temperature,
    sum(precipitation_mm) as total_weekly_rain,
    sum(max_snow_mm) as total_weekly_snow,
    avg(avg_wind_speed_kmh) as avg_wind_speed_weekly,
    avg(avg_wind_direction) as avg_wind_direction_weekly,
    max(wind_peakgust_kmh) as max_wind_gust_weekly,
    sum(sun_minutes) as total_sun_minutes_weekly
from daily
group by 1,2