USE DATABASE frostbyte_tasty_bytes;
USE SCHEMA raw_pos;

-- SELECT served_ts, dateadd(month,26,served_ts) as new_date FROM ORDER_HEADER order by  new_date desc limit 10;

UPDATE order_header SET order_ts = dateadd(day,60,order_ts); 
UPDATE order_header SET order_ts = dateadd(month,datediff(month,'2021-01-01',current_date),order_ts); 

SELECT  datediff(month,'2021-01-01',current_date); 

SELECT order_ts, dateadd(year,3,order_ts) FROM order_header limit 10; 

select max(order_ts)  , min(order_ts) from frostbyte_tasty_bytes.raw_pos.order_header;


WITH date_diff AS (
    SELECT datediff(day,MAX(order_ts),CURRENT_DATE) AS shift_days
    FROM order_header
)
SELECT order_ts AS old_date, 
       DATEADD(DAY,  (SELECT shift_days FROM date_diff), order_ts) AS new_date
FROM order_header limit 10;


select datediff(month,current_date,order_ts) FROM order_header limit 1;

USE SCHEMA RAW_CUSTOMER;
SELECT 
       SPLIT_PART(METADATA$FILENAME, '/', 4) as source_name,
       CONCAT(SPLIT_PART(METADATA$FILENAME, '/', 2),'/' ,SPLIT_PART(METADATA$FILENAME, '/', 3)) as quarter,
       $1 as order_id,
       $2 as truck_id,
       $3 as language,
       $5 as review,
       $6 as primary_city, 
       $7 as customer_id,
       $8 as year,
       $9 as month,
       $10 as truck_brand,
      DATEADD(month,-UNIFORM(0,6,RANDOM()),CURRENT_DATE()) as review_date
FROM @stg_truck_reviews 
(FILE_FORMAT => 'FF_CSV',
PATTERN => '.*reviews.*[.]csv') 
WHERE YEAR = '2022'
limit 100;


desc view frostbyte_tasty_bytes.analytics.product_unified_reviews;

select count(distinct review_date) from frostbyte_tasty_bytes.analytics.product_unified_reviews;

SELECT 
    o.date,
    round(SUM(ZEROIFNULL(o.price))) AS daily_sales
FROM frostbyte_tasty_bytes.analytics.orders_v o
WHERE 1=1
    AND o.country = 'Germany'
    AND o.primary_city = 'Hamburg'
    AND DATE(o.order_ts) BETWEEN '2024-02-10' AND '2024-02-25'
GROUP BY o.date 
--HAVING daily_sales <= 0
ORDER BY o.date ASC ;

SELECT 
    dw.country_desc,
    dw.city_name,
    dw.date_valid_std,
    AVG(dw.avg_temperature_air_2m_f) AS avg_temperature_air_2m_f
FROM frostbyte_tasty_bytes.harmonized.daily_weather_v dw
WHERE 1=1
    AND dw.country_desc = 'Germany'
    AND dw.city_name = 'Hamburg'
    AND YEAR(date_valid_std) = '2024'
    AND MONTH(date_valid_std) = '2'
GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
ORDER BY dw.date_valid_std DESC;

SELECT 
    dw.country_desc,
    dw.city_name,
    dw.date_valid_std,
    MAX(dw.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
FROM frostbyte_tasty_bytes.harmonized.daily_weather_v dw
WHERE 1=1
    AND dw.country_desc IN ('Germany')
    AND dw.city_name = 'Hamburg'
    AND YEAR(date_valid_std) = '2024'
    AND MONTH(date_valid_std) = '2'
    AND date_valid_std between '2024-02-10' and  '2024-02-25'
GROUP BY dw.country_desc, dw.city_name, dw.date_valid_std
ORDER BY dw.date_valid_std ASC;

SELECT 
    fd.date_valid_std AS date,
    fd.city_name,
    fd.country_desc,
    ZEROIFNULL(SUM(odv.price)) AS daily_sales,
    ROUND(AVG(fd.avg_temperature_air_2m_f),2) AS avg_temperature_fahrenheit,
    ROUND(AVG(frostbyte_tasty_bytes.analytics.fahrenheit_to_celsius(fd.avg_temperature_air_2m_f)),2) AS avg_temperature_celsius,
    ROUND(AVG(fd.tot_precipitation_in),2) AS avg_precipitation_inches,
    ROUND(AVG(frostbyte_tasty_bytes.analytics.inch_to_millimeter(fd.tot_precipitation_in)),2) AS avg_precipitation_millimeters,
    MAX(fd.max_wind_speed_100m_mph) AS max_wind_speed_100m_mph
FROM frostbyte_tasty_bytes.harmonized.daily_weather_v fd
LEFT JOIN frostbyte_tasty_bytes.harmonized.orders_v odv
    ON fd.date_valid_std = DATE(odv.order_ts)
    AND fd.city_name = odv.primary_city
    AND fd.country_desc = odv.country
WHERE 1=1
    AND fd.country_desc = 'Germany'
    AND fd.city = 'Hamburg'
    AND fd.yyyy_mm = '2024-02'
    AND date_valid_std between '2024-02-10' and  '2024-02-25'
GROUP BY fd.date_valid_std, fd.city_name, fd.country_desc
ORDER BY fd.date_valid_std ASC;



SELECT 
    dcm.date,
    dcm.city_name,
    dcm.country_desc,
    dcm.daily_sales,
    dcm.avg_temperature_fahrenheit,
    dcm.avg_temperature_celsius,
    dcm.avg_precipitation_inches,
    dcm.avg_precipitation_millimeters,
    dcm.max_wind_speed_100m_mph
FROM frostbyte_tasty_bytes.analytics.daily_city_metrics_v dcm
WHERE 1=1
    AND dcm.country_desc = 'Germany'
    AND dcm.city_name = 'Hamburg'
    AND dcm.date BETWEEN '2024-02-10' AND '2024-02-25'
ORDER BY date ASC;