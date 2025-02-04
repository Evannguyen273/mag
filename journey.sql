-- 1. Delivery Performance Analysis
WITH delivery_metrics AS (
    SELECT 
        deliverytype,
        carrier,
        COUNT(*) as total_deliveries,
        SUM(CASE WHEN is_on_time = 'Y' THEN 1 ELSE 0 END) as on_time_deliveries,
        AVG(consignment_deliverycost) as avg_delivery_cost,
        SUM(CASE WHEN is_delivery_failure = 'Y' THEN 1 ELSE 0 END) as failed_deliveries
    FROM online_journey
    GROUP BY deliverytype, carrier
)
SELECT 
    *,
    ROUND((on_time_deliveries * 100.0 / total_deliveries), 2) as on_time_percentage,
    ROUND((failed_deliveries * 100.0 / total_deliveries), 2) as failure_rate
FROM delivery_metrics
ORDER BY total_deliveries DESC;

-- 2. Product Category Performance
SELECT 
    product_group_name,
    product_type_name,
    COUNT(DISTINCT orderid) as total_orders,
    COUNT(*) as total_items,
    AVG(product_price) as avg_price,
    SUM(CASE WHEN is_return_flag = 'Y' THEN 1 ELSE 0 END) as returns,
    ROUND(SUM(CASE WHEN is_return_flag = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as return_rate,
    SUM(CASE WHEN deliverymode = '1' THEN 1 ELSE 0 END) as express_deliveries
FROM online_journey
GROUP BY product_group_name, product_type_name
HAVING COUNT(*) > 100
ORDER BY total_orders DESC;

-- 3. Geographic Analysis
SELECT 
    country,
    town,
    COUNT(DISTINCT orderid) as total_orders,
    COUNT(*) as total_items,
    AVG(consignment_deliverycost) as avg_delivery_cost,
    SUM(CASE WHEN is_on_time = 'N' THEN 1 ELSE 0 END) as delayed_deliveries,
    SUM(CASE WHEN is_return_flag = 'Y' THEN 1 ELSE 0 END) as returns,
    SUM(CASE WHEN deliverymode = '1' THEN 1 ELSE 0 END) as express_deliveries
FROM online_journey
GROUP BY country, town
HAVING COUNT(DISTINCT orderid) > 50
ORDER BY total_orders DESC;

-- 4. Picking Issues Analysis
SELECT 
    warehouseid,
    COUNT(*) as total_items,
    SUM(CASE WHEN is_short_pick = 'Y' THEN 1 ELSE 0 END) as short_picks,
    SUM(CASE WHEN is_zero_pick = 'Y' THEN 1 ELSE 0 END) as zero_picks,
    ROUND(AVG(CASE WHEN is_short_pick = 'Y' THEN 1 ELSE 0 END) * 100, 2) as short_pick_rate,
    ROUND(AVG(CASE WHEN is_zero_pick = 'Y' THEN 1 ELSE 0 END) * 100, 2) as zero_pick_rate,
    SUM(CASE WHEN is_delivery_failure = 'Y' THEN 1 ELSE 0 END) as delivery_failures
FROM online_journey
GROUP BY warehouseid
ORDER BY total_items DESC;

-- 5. Delivery Mode Analysis
SELECT 
    deliverymode,
    deliverytype,
    COUNT(*) as total_orders,
    AVG(consignment_deliverycost) as avg_delivery_cost,
    SUM(CASE WHEN is_on_time = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as on_time_rate,
    SUM(CASE WHEN is_delivery_failure = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as failure_rate,
    SUM(CASE WHEN is_return_flag = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as return_rate
FROM online_journey
GROUP BY deliverymode, deliverytype
ORDER BY deliverymode, total_orders DESC;

-- 6. Combined Performance Metrics
SELECT 
    DATE_TRUNC('month', orderdate_timestamp) as order_month,
    COUNT(DISTINCT orderid) as total_orders,
    SUM(CASE WHEN is_on_time = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as on_time_rate,
    SUM(CASE WHEN is_short_pick = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as short_pick_rate,
    SUM(CASE WHEN is_zero_pick = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as zero_pick_rate,
    SUM(CASE WHEN is_return_flag = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as return_rate,
    SUM(CASE WHEN is_delivery_failure = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as failure_rate,
    SUM(CASE WHEN deliverymode = '1' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as express_delivery_rate
FROM online_journey
GROUP BY DATE_TRUNC('month', orderdate_timestamp)
ORDER BY order_month;


--------------------------------------------------------------


-- 1. Day of Week Analysis
SELECT 
    EXTRACT(DAYOFWEEK FROM orderdate_timestamp) as day_of_week,
    FORMAT_TIMESTAMP('%A', orderdate_timestamp) as day_name,
    COUNT(DISTINCT orderid) as total_orders,
    COUNT(*) as total_items,
    ROUND(AVG(consignment_deliverycost), 2) as avg_delivery_cost,
    ROUND(COUNTIF(is_on_time = 'Y') * 100.0 / COUNT(*), 2) as on_time_rate,
    ROUND(COUNTIF(is_delivery_failure = 'Y') * 100.0 / COUNT(*), 2) as failure_rate,
    ROUND(COUNTIF(deliverymode = '1') * 100.0 / COUNT(*), 2) as express_delivery_rate,
    ROUND(COUNTIF(is_return_flag = 'Y') * 100.0 / COUNT(*), 2) as return_rate
FROM `your_project.your_dataset.online_journey`
GROUP BY day_of_week, day_name
ORDER BY day_of_week;

-- 2. Weekly Trends Over Time
WITH weekly_metrics AS (
    SELECT 
        DATE_TRUNC(orderdate_timestamp, WEEK) as week_start,
        COUNT(DISTINCT orderid) as total_orders,
        COUNT(*) as total_items,
        ROUND(AVG(consignment_deliverycost), 2) as avg_delivery_cost,
        ROUND(COUNTIF(is_on_time = 'Y') * 100.0 / COUNT(*), 2) as on_time_rate,
        ROUND(COUNTIF(is_delivery_failure = 'Y') * 100.0 / COUNT(*), 2) as failure_rate,
        ROUND(COUNTIF(is_return_flag = 'Y') * 100.0 / COUNT(*), 2) as return_rate
    FROM `your_project.your_dataset.online_journey`
    GROUP BY week_start
)
SELECT 
    *,
    AVG(total_orders) OVER (
        ORDER BY week_start
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) as moving_avg_orders,
    AVG(on_time_rate) OVER (
        ORDER BY week_start
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) as moving_avg_on_time_rate
FROM weekly_metrics
ORDER BY week_start;

-- 3. Peak Hours by Day of Week
SELECT 
    EXTRACT(DAYOFWEEK FROM orderdate_timestamp) as day_of_week,
    FORMAT_TIMESTAMP('%A', orderdate_timestamp) as day_name,
    EXTRACT(HOUR FROM orderdate_timestamp) as hour_of_day,
    COUNT(DISTINCT orderid) as total_orders,
    ROUND(COUNTIF(deliverymode = '1') * 100.0 / COUNT(*), 2) as express_delivery_rate,
    ROUND(COUNTIF(is_on_time = 'Y') * 100.0 / COUNT(*), 2) as on_time_rate
FROM `your_project.your_dataset.online_journey`
GROUP BY day_of_week, day_name, hour_of_day
ORDER BY day_of_week, total_orders DESC;

-- 4. Weekly Performance by Warehouse
SELECT 
    warehouseid,
    DATE_TRUNC(orderdate_timestamp, WEEK) as week_start,
    COUNT(*) as total_items,
    ROUND(COUNTIF(is_short_pick = 'Y') * 100.0 / COUNT(*), 2) as short_pick_rate,
    ROUND(COUNTIF(is_zero_pick = 'Y') * 100.0 / COUNT(*), 2) as zero_pick_rate,
    ROUND(COUNTIF(is_on_time = 'Y') * 100.0 / COUNT(*), 2) as on_time_rate
FR


-- 4. Weekly Performance by Warehouse
SELECT 
    warehouseid,
    DATE_TRUNC(orderdate_timestamp, WEEK) as week_start,
    COUNT(*) as total_items,
    ROUND(COUNTIF(is_short_pick = 'Y') * 100.0 / COUNT(*), 2) as short_pick_rate,
    ROUND(COUNTIF(is_zero_pick = 'Y') * 100.0 / COUNT(*), 2) as zero_pick_rate,
    ROUND(COUNTIF(is_on_time = 'Y') * 100.0 / COUNT(*), 2) as on_time_rate,
    -- Additional metrics
    ROUND(AVG(consignment_deliverycost), 2) as avg_delivery_cost,
    ROUND(COUNTIF(is_delivery_failure = 'Y') * 100.0 / COUNT(*), 2) as delivery_failure_rate,
    ROUND(COUNTIF(is_return_flag = 'Y') * 100.0 / COUNT(*), 2) as return_rate,
    ROUND(COUNTIF(deliverymode = '1') * 100.0 / COUNT(*), 2) as express_delivery_rate,
    COUNT(DISTINCT orderid) as total_orders,
    -- Efficiency metrics
    ROUND(COUNT(*) / COUNT(DISTINCT orderid), 2) as items_per_order,
    -- Time metrics
    AVG(TIMESTAMP_DIFF(delivery_date, orderdate_timestamp, HOUR)) as avg_delivery_time_hours
FROM `your_project.your_dataset.online_journey`
WHERE 
    orderdate_timestamp IS NOT NULL
    AND warehouseid IS NOT NULL
GROUP BY 
    warehouseid,
    week_start
HAVING 
    total_items >= 10  -- Filter out weeks with very low volume
ORDER BY 
    warehouseid,
    week_start;
