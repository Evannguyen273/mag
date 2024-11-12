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






---------
def analyze_warehouse_performance(df):
    fig = plt.figure(figsize=(20, 25))
    
    # 1. Volume and Efficiency Matrix
    ax1 = plt.subplot(3, 2, 1)
    scatter = ax1.scatter(df['avg_processing_days'],
                         df['on_time_rate'],
                         s=df['total_orders']/1000,
                         c=df['delivery_failure_rate'],
                         cmap='RdYlGn_r',
                         alpha=0.7)
    
    for idx, row in df.iterrows():
        ax1.annotate(row['warehouseid'],
                    (row['avg_processing_days'], row['on_time_rate']),
                    xytext=(5, 5), textcoords='offset points')
    
    ax1.set_xlabel('Average Processing Days')
    ax1.set_ylabel('On-Time Rate (%)')
    ax1.set_title('Warehouse Efficiency Matrix\n(Size: Order Volume, Color: Failure Rate)')
    ax1.grid(True, linestyle='--', alpha=0.7)
    plt.colorbar(scatter, label='Delivery Failure Rate (%)')
    
    # 2. Processing vs Delivery Time
    ax2 = plt.subplot(3, 2, 2)
    scatter2 = ax2.scatter(df['avg_processing_days'],
                          df['avg_delivery_days'],
                          s=df['total_orders']/1000,
                          c=df['on_time_rate'],
                          cmap='RdYlGn',
                          alpha=0.7)
    
    for idx, row in df.iterrows():
        ax2.annotate(row['warehouseid'],
                    (row['avg_processing_days'], row['avg_delivery_days']),
                    xytext=(5, 5), textcoords='offset points')
    
    ax2.set_xlabel('Average Processing Days')
    ax2.set_ylabel('Average Delivery Days')
    ax2.set_title('Processing vs Delivery Time\n(Size: Order Volume, Color: On-Time Rate)')
    ax2.grid(True, linestyle='--', alpha=0.7)
    plt.colorbar(scatter2, label='On-Time Rate (%)')
    
    # 3. Pick Issues and Volume
    ax3 = plt.subplot(3, 2, 3)
    top_warehouses = df.nlargest(8, 'total_orders')
    
    x = np.arange(len(top_warehouses))
    width = 0.35
    
    ax3.bar(x - width/2, top_warehouses['short_pick_rate'], width, label='Short Pick Rate', color='skyblue')
    ax3.bar(x + width/2, top_warehouses['zero_pick_rate'], width, label='Zero Pick Rate', color='lightcoral')
    
    ax3.set_xticks(x)
    ax3.set_xticklabels(top_warehouses['warehouseid'], rotation=45)
    ax3.set_ylabel('Rate (%)')
    ax3.set_title('Pick Issues by Warehouse\n(Top 8 by Volume)')
    ax3.grid(True, linestyle='--', alpha=0.7)
    ax3.legend()
    
    # 4. Volume and Value Analysis
    ax4 = plt.subplot(3, 2, 4)
    scatter3 = ax4.scatter(df['avg_order_value'],
                          df['on_time_rate'],
                          s=df['total_orders']/1000,
                          c=df['late_processing_rate'],
                          cmap='RdYlGn_r',
                          alpha=0.7)
    
    for idx, row in df.iterrows():
        ax4.annotate(row['warehouseid'],
                    (row['avg_order_value'], row['on_time_rate']),
                    xytext=(5, 5), textcoords='offset points')
    
    ax4.set_xlabel('Average Order Value')
    ax4.set_ylabel('On-Time Rate (%)')
    ax4.set_title('Value vs Performance\n(Size: Order Volume, Color: Late Processing Rate)')
    ax4.grid(True, linestyle='--', alpha=0.7)
    plt.colorbar(scatter3, label='Late Processing Rate (%)')
    
    # 5. Peak Load Analysis
    ax5 = plt.subplot(3, 2, 5)
    scatter4 = ax5.scatter(df['peak_load_ratio'],
                          df['on_time_rate'],
                          s=df['total_orders']/1000,
                          c=df['processing_time_stddev'],
                          cmap='viridis',
                          alpha=0.7)
    
    for idx, row in df.iterrows():
        ax5.annotate(row['warehouseid'],
                    (row['peak_load_ratio'], row['on_time_rate']),
                    xytext=(5, 5), textcoords='offset points')
    
    ax5.set_xlabel('Peak Load Ratio')
    ax5.set_ylabel('On-Time Rate (%)')
    ax5.set_title('Peak Load Impact\n(Size: Order Volume, Color: Processing Time StdDev)')
    ax5.grid(True, linestyle='--', alpha=0.7)
    plt.colorbar(scatter4, label='Processing Time StdDev')
    
    plt.tight_layout()
    plt.show()

# Run the analysis
analyze_warehouse_performance(df)

# Print summary statistics
print("\nWarehouse Performance Summary:")
print("\nTop 3 Warehouses by Volume:")
print(df.nlargest(3, 'total_orders')[['warehouseid', 'total_orders', 'on_time_rate', 'avg_processing_days']])

print("\nTop 3 Warehouses by On-Time Rate (min 10,000 orders):")
high_volume_df = df[df['total_orders'] >= 10000]
print(high_volume_df.nlargest(3, 'on_time_rate')[['warehouseid', 'on_time_rate', 'total_orders', 'avg_processing_days']])

print("\nWarehouse Efficiency Metrics:")
print(f"Average Processing Time: {df['avg_processing_days'].mean():.2f} days")
print(f"Average On-Time Rate: {df['on_time_rate'].mean():.2f}%")
print(f"Average Pick Issue Rate: {df['pick_issue_rate'].mean():.2f}%")



++++++++++++++


# Warehouse Performance Analysis

## Volume Distribution
* **High-Volume Warehouses** (>100,000 orders):
  - W065: 997,741 orders (Primary distribution center)
  - W388: 295,650 orders
  - W067: 133,123 orders

* **Mid-Volume Warehouses** (10,000-100,000 orders):
  - W198: 76,634 orders
  - W196: 61,120 orders
  - W195: 48,579 orders
  - W197: 27,358 orders
  - W194: 26,644 orders

* **Low-Volume Warehouses** (<10,000 orders):
  - 4 warehouses handling specialized or backup operations

## Processing Efficiency

### Processing Time
* **Fastest Processing**: W252 (0.65 days)
* **Slowest Processing**: W666 (3.35 days)
* **High-Volume Efficiency**:
  - W067: 1.40 days (excellent for high volume)
  - W065: 1.95 days (good for highest volume)

### Delivery Time
* **Fastest Average Delivery**: W388 (4.17 days)
* **Slowest Average Delivery**: W068 (74.52 days)
* **High-Volume Performance**:
  - W065: 4.70 days (efficient for primary warehouse)
  - W388: 4.17 days (excellent performance)

## Quality Metrics

### Pick Accuracy
* **Best Performers**:
  - W194: 0.17% short pick rate
  - W195: 0.26% short pick rate
* **Needs Improvement**:
  - V011: 13.34% short pick rate
  - W666: 1.02% short pick rate

### On-Time Performance
* **Top Performers** (>80%):
  - W067: 82.37%
  - W388: 81.01%
  - W065: 79.62%
* **Struggling Warehouses**:
  - W666: 0%
  - W068: 0%
  - V011: 31.02%

## Peak Load Handling
* **Most Consistent**: W666 (2.61 peak ratio)
* **Highest Variation**: W252 (14.78 peak ratio)
* **High-Volume Stability**:
  - W065: 6.34 ratio (good for volume)
  - W388: 3.04 ratio (excellent stability)

## Key Insights

1. **Volume Management**:
   * W065 demonstrates excellent scalability
   * W388 shows optimal balance of volume and performance
   * Smaller warehouses show higher variability

2. **Efficiency Patterns**:
   * Processing time generally correlates with volume
   * Larger warehouses maintain better consistency
   * Peak load handling varies significantly

3. **Critical Issues**:
   * Some warehouses showing 0% on-time rate
   * High short pick rates in specific locations
   * Significant processing time variations

## Recommendations

1. **Process Standardization**:
   * Implement W388's practices across network
   * Focus on reducing processing time variation
   * Standardize peak load handling procedures

2. **Quality Improvement**:
   * Address pick accuracy issues in V011
   * Investigate delivery failures in low-performing warehouses
   * Implement systematic quality controls

3. **Volume Optimization**:
   * Redistribute load from struggling warehouses
   * Optimize resource allocation during peak periods
   * Consider capacity expansion in efficient locations
