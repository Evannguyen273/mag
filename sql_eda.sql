WITH daily_metrics AS (
    SELECT 
        DATE(orderdate_timestamp) as delivery_day,
        deliverytype,
        COUNT(*) as total_deliveries,
        ROUND(AVG(CASE WHEN is_on_time = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as ontime_rate,
        ROUND(AVG(CASE WHEN is_delivery_failure = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as failure_rate,
        ROUND(AVG(CASE WHEN is_return_flag = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as return_rate,
        ROUND(AVG(CASE WHEN is_short_pick = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as short_pick_rate,
        ROUND(AVG(CASE WHEN is_zero_pick = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as zero_pick_rate
    FROM tableA
    GROUP BY 
        DATE(orderdate_timestamp),
        deliverytype
)
SELECT 
    delivery_day,
    deliverytype,
    ontime_rate,
    failure_rate,
    return_rate,
    short_pick_rate,
    zero_pick_rate,
    total_deliveries
FROM daily_metrics
ORDER BY 
    deliverytype,
    delivery_day;



--------------
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def plot_delivery_metrics(data, delivery_type):
    """
    Input:
    data: DataFrame filtered for specific delivery type
    delivery_type: string of delivery type name
    """
    plt.figure(figsize=(12, 6))
    
    # Create primary axis for rates
    ax1 = plt.gca()
    
    # Plot rates on primary y-axis
    ax1.plot(data['delivery_day'], data['ontime_rate'], marker='o', markersize=4, 
            label='On-time Rate', color='green', linewidth=1)
    ax1.plot(data['delivery_day'], data['failure_rate'], marker='s', markersize=4, 
            label='Failure Rate', color='red', linewidth=1)
    ax1.plot(data['delivery_day'], data['return_rate'], marker='^', markersize=4, 
            label='Return Rate', color='blue', linewidth=1)
    ax1.plot(data['delivery_day'], data['short_pick_rate'], marker='D', markersize=4, 
            label='Short Pick Rate', color='purple', linewidth=1)
    ax1.plot(data['delivery_day'], data['zero_pick_rate'], marker='v', markersize=4, 
            label='Zero Pick Rate', color='orange', linewidth=1)
    
    # Create secondary axis for total deliveries
    ax2 = ax1.twinx()
    ax2.bar(data['delivery_day'], data['total_deliveries'], alpha=0.2, color='gray', 
            label='Total Deliveries')
    
    # Set labels and title
    plt.title(f'Delivery Performance Metrics - {delivery_type.replace("_", " ")}', pad=20)
    ax1.set_xlabel('Date')
    ax1.set_ylabel('Rate (%)')
    ax2.set_ylabel('Total Deliveries')
    
    # Customize grid and appearance
    ax1.grid(True, linestyle='--', alpha=0.7)
    plt.xticks(rotation=45)
    
    # Set y-axis ranges
    ax1.set_ylim(0, 100)
    ax2.set_ylim(0, data['total_deliveries'].max() * 1.1)
    
    # Combine legends from both axes
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, 
              loc='upper center', bbox_to_anchor=(0.5, -0.15), 
              ncol=3, fontsize=8)
    
    plt.tight_layout()
    plt.show()

# Read the CSV file
df = pd.read_csv('delivery_metrics.csv')
df['delivery_day'] = pd.to_datetime(df['delivery_day'])

# Plot for each delivery type
for delivery_type in df['deliverytype'].unique():
    type_data = df[df['deliverytype'] == delivery_type].sort_values('delivery_day')
    plot_delivery_metrics(type_data, delivery_type)


CLICK_AND_COLLECT:


Characteristics:

Lower volume delivery option
Inconsistent on-time performance
Higher operational issues (short picks/zero picks)


Average daily volume: ~150-200 deliveries
High variability in return rates (0-100%)
Best suited for: Local store pickup with flexible timing


CNC_STANDARD:


Characteristics:

Medium-high volume
Stable return rates (~45-50%)
Improving on-time performance over time


Significant volume growth in later months
Good balance of speed and reliability
Best suited for: Standard click-and-collect orders


HOME_DELIVERY_EXPRESS:


Characteristics:

Premium service with high on-time rates
Lower volumes
Variable return rates


Higher operational costs (implied by low volumes)
Best suited for: Time-sensitive deliveries


HOME_DELIVERY_STANDARD:


Characteristics:

Highest volume service
Most consistent performance
Strong on-time rates (80%+)


Very scalable operation
Stable return rates
Best suited for: Bulk of home delivery operations


PUP_STANDARD (Pickup Standard):


Characteristics:

High volume
Consistent performance
Lower return rates than home delivery


Good balance of efficiency and reliability
Best suited for: Standard pickup services


PUP_LOCKER Variants:


Characteristics:

Medium volume
Technology-dependent service
Good efficiency metrics


Growing service with improving metrics
Best suited for: Contactless pickup options

Key Operational Insights:

Volume Impact:


Higher volumes generally correlate with better performance
Return rates remain relatively stable across volumes
Failure rates slightly increase with volume


Seasonal Patterns:


Most services show peak volumes in May-June
Performance metrics generally stable across seasons
Return rates show some seasonal variation


Service Evolution:


Newer services show improvement over time
More established services have stable metrics
Technology-dependent services show more variability
