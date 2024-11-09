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
