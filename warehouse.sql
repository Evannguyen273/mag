WITH warehouse_metrics AS (
    SELECT 
        warehouseid,
        -- Order Processing Time
        AVG(TIMESTAMP_DIFF(CAST(shippingdate_timestamp AS TIMESTAMP), 
                          CAST(orderdate_timestamp AS TIMESTAMP), DAY)) as avg_processing_days,
        -- Delivery Time
        AVG(TIMESTAMP_DIFF(CAST(delivery_date AS TIMESTAMP), 
                          CAST(shippingdate_timestamp AS TIMESTAMP), DAY)) as avg_delivery_days,
        -- Order Volume
        COUNT(DISTINCT orderid) as total_orders,
        -- Success Metrics
        AVG(IF(is_short_pick = 'Y', 1, 0)) * 100 as short_pick_rate,
        AVG(IF(is_zero_pick = 'Y', 1, 0)) * 100 as zero_pick_rate,
        AVG(IF(is_on_time = 'Y', 1, 0)) * 100 as on_time_rate,
        AVG(IF(is_delivery_failure = 'Y', 1, 0)) * 100 as delivery_failure_rate,
        -- Order Value Metrics
        AVG(CAST(product_price AS FLOAT64)) as avg_order_value,
        SUM(CAST(product_price AS FLOAT64)) as total_revenue,
        -- Efficiency Metrics
        COUNT(DISTINCT CASE WHEN is_short_pick = 'Y' OR is_zero_pick = 'Y' THEN orderid END) * 100.0 / 
            NULLIF(COUNT(DISTINCT orderid), 0) as pick_issue_rate,
        COUNT(DISTINCT CASE WHEN TIMESTAMP_DIFF(CAST(shippingdate_timestamp AS TIMESTAMP), 
                                              CAST(orderdate_timestamp AS TIMESTAMP), DAY) > 2 
                      THEN orderid END) * 100.0 / 
            NULLIF(COUNT(DISTINCT orderid), 0) as late_processing_rate
    FROM orders
    WHERE orderdate_timestamp IS NOT NULL 
      AND shippingdate_timestamp IS NOT NULL
    GROUP BY warehouseid
),
daily_metrics AS (
    SELECT 
        warehouseid,
        DATE(orderdate_timestamp) as order_date,
        COUNT(DISTINCT orderid) as daily_orders,
        AVG(TIMESTAMP_DIFF(CAST(shippingdate_timestamp AS TIMESTAMP), 
                          CAST(orderdate_timestamp AS TIMESTAMP), DAY)) as daily_processing_time
    FROM orders
    WHERE orderdate_timestamp IS NOT NULL 
      AND shippingdate_timestamp IS NOT NULL
    GROUP BY warehouseid, DATE(orderdate_timestamp)
)
SELECT 
    w.*,
    -- Calculate processing time consistency
    STDDEV(d.daily_processing_time) as processing_time_stddev,
    -- Calculate daily order volume consistency
    STDDEV(d.daily_orders) as order_volume_stddev,
    -- Calculate peak vs average ratio
    MAX(d.daily_orders) / AVG(d.daily_orders) as peak_load_ratio
FROM warehouse_metrics w
LEFT JOIN daily_metrics d USING (warehouseid)
GROUP BY 
    w.warehouseid, w.avg_processing_days, w.avg_delivery_days, w.total_orders,
    w.short_pick_rate, w.zero_pick_rate, w.on_time_rate, w.delivery_failure_rate,
    w.avg_order_value, w.total_revenue, w.pick_issue_rate, w.late_processing_rate
ORDER BY w.total_orders DESC;
