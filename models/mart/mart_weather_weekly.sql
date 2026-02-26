{{ config(materialized='table') }}

with daily as (
    select * from {{ ref('prep_weather_daily') }}
)
select
    station_id,
    date_trunc('week', date) as week_start,
    avg(avg_temperature) as avg_weekly_temperature,
    max(max_temperature) as max_weekly_temperature,
    min(min_temperature) as min_weekly_temperature,
    sum(precipitation) as total_weekly_rain,
    sum(snowfall) as total_weekly_snow,
    sum(case when rainy_flag = 1 then 1 else 0 end) as rainy_days,
    sum(case when snowy_flag = 1 then 1 else 0 end) as snowy_days,
    sum(case when sunny_flag = 1 then 1 else 0 end) as sunny_days
from daily
group by 1,2