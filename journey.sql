-- 1. Delivery Performance Analysis
WITH delivery_metrics AS (
    SELECT 
        deliverytype,
        carrier,
        COUNT(*) as total_deliveries,
        SUM(CASE WHEN is_on_time = 'Yes' THEN 1 ELSE 0 END) as on_time_deliveries,
        AVG(consignment_deliverycost) as avg_delivery_cost,
        SUM(CASE WHEN is_delivery_failure = 1 THEN 1 ELSE 0 END) as failed_deliveries
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
    SUM(CASE WHEN is_return_flag = 'Yes' THEN 1 ELSE 0 END) as returns,
    ROUND(SUM(CASE WHEN is_return_flag = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as return_rate
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
    SUM(CASE WHEN is_on_time = 'No' THEN 1 ELSE 0 END) as delayed_deliveries,
    SUM(CASE WHEN is_return_flag = 'Yes' THEN 1 ELSE 0 END) as returns
FROM online_journey
GROUP BY country, town
HAVING COUNT(DISTINCT orderid) > 50
ORDER BY total_orders DESC;

-- 4. Picking Issues Analysis
SELECT 
    warehouseid,
    COUNT(*) as total_items,
    SUM(CASE WHEN is_short_pick = 'Yes' THEN 1 ELSE 0 END) as short_picks,
    SUM(CASE WHEN is_zero_pick = 'Yes' THEN 1 ELSE 0 END) as zero_picks,
    ROUND(AVG(CASE WHEN is_short_pick = 'Yes' THEN 1 ELSE 0 END) * 100, 2) as short_pick_rate,
    ROUND(AVG(CASE WHEN is_zero_pick = 'Yes' THEN 1 ELSE 0 END) * 100, 2) as zero_pick_rate
FROM online_journey
GROUP BY warehouseid
ORDER BY total_items DESC;

-- 5. Fashion Trend Analysis
SELECT 
    colour_group_name,
    product_group_name,
    COUNT(*) as total_items,
    COUNT(DISTINCT orderid) as unique_orders,
    AVG(product_price) as avg_price,
    SUM(CASE WHEN is_return_flag = 'Yes' THEN 1 ELSE 0 END) as returns
FROM online_journey
GROUP BY colour_group_name, product_group_name
HAVING COUNT(*) > 50
ORDER BY total_items DESC;

-- 6. Delivery Time Analysis
SELECT 
    deliverytype,
    AVG(DATEDIFF(day, orderdate_timestamp, delivery_date)) as avg_delivery_days,
    MIN(DATEDIFF(day, orderdate_timestamp, delivery_date)) as min_delivery_days,
    MAX(DATEDIFF(day, orderdate_timestamp, delivery_date)) as max_delivery_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(day, orderdate_timestamp, delivery_date)) 
        OVER (PARTITION BY deliverytype) as median_delivery_days
FROM online_journey
WHERE delivery_date IS NOT NULL
GROUP BY deliverytype;
