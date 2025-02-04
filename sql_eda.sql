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



-------------------------------------------
overall
SELECT 
    DATE(orderdate_timestamp) as delivery_date,
    ROUND(AVG(CASE WHEN is_on_time = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as ontime_rate,
    ROUND(AVG(CASE WHEN is_delivery_failure = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as failure_rate,
    ROUND(AVG(CASE WHEN is_return_flag = 'Y' THEN 1.0 ELSE 0.0 END) * 100, 1) as return_rate
FROM tableA
GROUP BY DATE(orderdate_timestamp)
ORDER BY delivery_date;



import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Assuming data is saved in 'delivery_trends.csv'
df = pd.read_csv('delivery_trends.csv')
df['delivery_date'] = pd.to_datetime(df['delivery_date'])

# Create the plot
plt.figure(figsize=(15, 8))

# Plot all lines
plt.plot(df['delivery_date'], df['ontime_rate'], 
         label='On-time Rate', color='green', linewidth=2)
plt.plot(df['delivery_date'], df['failure_rate'], 
         label='Failure Rate', color='red', linewidth=2)
plt.plot(df['delivery_date'], df['return_rate'], 
         label='Return Rate', color='blue', linewidth=2)

# Customize the plot
plt.title('Overall Delivery Performance Trends', fontsize=14, pad=20)
plt.xlabel('Date', fontsize=12)
plt.ylabel('Rate (%)', fontsize=12)
plt.grid(True, linestyle='--', alpha=0.7)
plt.legend(fontsize=10)

# Rotate x-axis labels for better readability
plt.xticks(rotation=45)

# Add some statistics annotations
mean_ontime = df['ontime_rate'].mean()
mean_failure = df['failure_rate'].mean()
mean_return = df['return_rate'].mean()

stats_text = f'Average Rates:\nOn-time: {mean_ontime:.1f}%\nFailure: {mean_failure:.1f}%\nReturn: {mean_return:.1f}%'
plt.text(0.02, 0.98, stats_text, 
         transform=plt.gca().transAxes, 
         verticalalignment='top',
         bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

# Adjust layout to prevent label cutoff
plt.tight_layout()

# Show the plot
plt.show()

# Print summary statistics
print("\nSummary Statistics:")
print(f"Date Range: {df['delivery_date'].min().strftime('%Y-%m-%d')} to {df['delivery_date'].max().strftime('%Y-%m-%d')}")
print(f"\nOn-time Rate:")
print(f"  Average: {df['ontime_rate'].mean():.1f}%")
print(f"  Min: {df['ontime_rate'].min():.1f}%")
print(f"  Max: {df['ontime_rate'].max():.1f}%")

print(f"\nFailure Rate:")
print(f"  Average: {df['failure_rate'].mean():.1f}%")
print(f"  Min: {df['failure_rate'].min():.1f}%")
print(f"  Max: {df['failure_rate'].max():.1f}%")

print(f"\nReturn Rate:")
print(f"  Average: {df['return_rate'].mean():.1f}%")
print(f"  Min: {df['return_rate'].min():.1f}%")
print(f"  Max: {df['return_rate'].max():.1f}%")


Analysis of Factors Affecting Performance:

Seasonal Patterns:

Winter (Dec-Feb):

High return rates initially (holiday returns)
Lower on-time performance
Challenging weather conditions
Holiday season peak volumes
Reasons:
Post-holiday returns surge
Weather-related delivery challenges
Peak shopping season strain

Spring (Mar-May):

Improved on-time rates
Stable return rates
Better overall performance
Reasons:
Better weather conditions
Post-holiday normalization
System improvements implemented

Summer (Jun-Aug):

Consistent performance
Lower return rates
Stable operations
Reasons:
Favorable weather
Lower overall volumes
Vacation season impact

Fall (Sep-Oct):

Declining on-time rates
Very low return rates
System changes visible
Reasons:
Pre-holiday preparation
System updates/changes
Volume increases


Operational Factors:

Initial Period (Late 2023):

System implementation phase
High return rates
No on-time tracking
Reasons:
New system deployment
Staff training period
Process refinement

Improvement Phase (Early 2024):

Rapidly improving metrics
Stabilizing operations
Better tracking
Reasons:
Learning curve benefits
Process optimization
System maturity

Peak Performance (Mid 2024):

Optimal operations
Balanced metrics
Consistent delivery
Reasons:
Mature processes
Trained staff
Optimized routes


Delivery Method Impact:

Click & Collect:

Higher short pick/zero pick rates
Variable performance
Reasons:
Store inventory dependencies
Staff availability
Space constraints

Home Delivery:

More consistent performance
Better on-time rates
Reasons:
Direct control over process
Route optimization
Professional delivery staff

Locker Delivery:

Technology dependent
Good efficiency
Reasons:
Automated systems
24/7 availability
Limited capacity


External Events Impact:

Holiday Seasons:

Increased volumes
Higher return rates
Performance pressure
Reasons:
Volume spikes
Staffing challenges
Customer behavior

Weather Events:

Performance variations
Regional impacts
Reasons:
Delivery delays
Safety considerations
Route adjustments


System/Process Evolution:

Early Stage:

No on-time tracking
Basic metrics
Reasons:
System implementation
Limited capabilities
Learning phase

Mature Stage:

Comprehensive tracking
Multiple metrics
Reasons:
System refinement
Process maturity
Better data collection


Recommendations:

Operational:

Prepare for seasonal variations
Maintain staffing flexibility
Optimize based on delivery type

System:

Continue monitoring trends
Implement predictive analytics
Enhanced tracking capabilities

Process:

Standardize across delivery types
Regular performance reviews
Continuous improvement focus

Would you like me to elaborate on any of these aspects or provide more specific analysis for certain periods or delivery methods?

--------------------------------------------------
Time series
SELECT 
    DATE(orderdate_timestamp) as order_day,
    COUNT(DISTINCT orderid) as number_of_orders,
    ROUND(SUM(product_price), 2) as daily_revenue,
    ROUND(SUM(product_price) / COUNT(DISTINCT orderid), 2) as avg_order_value
FROM tableA
GROUP BY DATE(orderdate_timestamp)
ORDER BY order_day;

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Read data
df = pd.read_csv('revenue_data.csv')
df['order_day'] = pd.to_datetime(df['order_day'])

# Calculate weekly totals
df['week'] = df['order_day'].dt.isocalendar().week
df['year'] = df['order_day'].dt.isocalendar().year
df['year_week'] = df['order_day'].dt.strftime('%Y-%U')

weekly_revenue = df.groupby('year_week').agg({
    'daily_revenue': 'sum',
    'order_day': 'first'  # Keep first day of week for plotting
}).reset_index()

# Create figure with two y-axes
fig, ax1 = plt.subplots(figsize=(15, 8))

# Plot daily revenue on left y-axis
ax1.plot(df['order_day'], df['daily_revenue'], 
         color='blue', alpha=0.5, linewidth=1, 
         label='Daily Revenue')

# Add 7-day moving average
df['rolling_avg'] = df['daily_revenue'].rolling(window=7).mean()
ax1.plot(df['order_day'], df['rolling_avg'], 
         color='green', linewidth=2, linestyle='--', 
         label='7-day Moving Average')

# Create second y-axis for weekly revenue
ax2 = ax1.twinx()
ax2.plot(weekly_revenue['order_day'], weekly_revenue['daily_revenue'], 
         color='red', linewidth=2, label='Weekly Total')

# Customize the plot
ax1.set_xlabel('Date', fontsize=12)
ax1.set_ylabel('Daily Revenue', fontsize=12)
ax2.set_ylabel('Weekly Revenue', fontsize=12)
plt.title('Revenue Trends - Daily vs Weekly', fontsize=14, pad=20)

# Add grid
ax1.grid(True, linestyle='--', alpha=0.7)

# Combine legends
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')

# Rotate x-axis labels
plt.xticks(rotation=45)

# Add statistics annotations
stats_text = (
    f'Average Daily Revenue: {df["daily_revenue"].mean():,.2f}\n'
    f'Average Weekly Revenue: {weekly_revenue["daily_revenue"].mean():,.2f}\n'
    f'Peak Daily Revenue: {df["daily_revenue"].max():,.2f}\n'
    f'Peak Weekly Revenue: {weekly_revenue["daily_revenue"].max():,.2f}'
)
plt.text(0.02, 0.98, stats_text,
         transform=ax1.transAxes,
         verticalalignment='top',
         bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

# Print summary statistics
print("\nDaily Revenue Statistics:")
print(df['daily_revenue'].describe())

print("\nWeekly Revenue Statistics:")
print(weekly_revenue['daily_revenue'].describe())

# Calculate week-over-week growth
weekly_revenue['wow_growth'] = weekly_revenue['daily_revenue'].pct_change() * 100
print("\nWeek-over-Week Growth Statistics:")
print(weekly_revenue['wow_growth'].describe())

# Find weeks with highest and lowest revenue
print("\nTop 5 Highest Revenue Weeks:")
print(weekly_revenue.nlargest(5, 'daily_revenue')[['year_week', 'daily_revenue']])

print("\nTop 5 Lowest Revenue Weeks:")
print(weekly_revenue.nsmallest(5, 'daily_revenue')[['year_week', 'daily_revenue']])

plt.tight_layout()
plt.show()



==============
SELECT 
    DATE(orderdate_timestamp) as order_day,
    EXTRACT(ISOYEAR FROM orderdate_timestamp) as iso_year,
    EXTRACT(WEEK FROM orderdate_timestamp) as iso_week,
    CONCAT(EXTRACT(ISOYEAR FROM orderdate_timestamp), '-', 
           LPAD(EXTRACT(WEEK FROM orderdate_timestamp)::text, 2, '0')) as iso_year_week,
    SUM(product_price) as daily_revenue,
    SUM(SUM(product_price)) OVER (
        PARTITION BY EXTRACT(ISOYEAR FROM orderdate_timestamp), 
                     EXTRACT(WEEK FROM orderdate_timestamp)
    ) as weekly_revenue
FROM tableA
GROUP BY 
    DATE(orderdate_timestamp),
    EXTRACT(ISOYEAR FROM orderdate_timestamp),
    EXTRACT(WEEK FROM orderdate_timestamp)
ORDER BY order_day;


# Revenue Surge Analysis

## Major Revenue Events

### 1. Late January 2024 Surge (Week 4)
* January 28: $44.7M
* January 29: $54.2M (highest daily revenue)
* The entire week (Week 4) generated $148.6M, which was unprecedented at that point
* This represented a massive jump from the previous weeks where daily revenues were typically under $1M

### 2. September 25, 2024 Spike
* A single-day surge of $211M
* This was the highest single-day revenue in the entire dataset
* Week 38 totaled $338.3M, largely due to this spike
* The days before and after this spike showed normal revenue patterns ($15-24M per day)

### 3. October 27, 2024 Surge
* A significant spike of $136.4M
* This was followed by a sharp return to normal levels
* Week 43 totaled $192.1M, mostly due to this single day

## Notable Patterns
* These surges appear to be isolated events rather than gradual increases
* After each surge, revenue typically returns to baseline levels
* The baseline revenue increased significantly after the January surge, moving from thousands to millions per day
* The surge events might represent special sales events, product launches, or major business developments
* There's also a pattern of elevated weekly revenues when major retailers typically have sales events (like Black Friday, Cyber Monday, etc.)
    ---------------------------------------

# Canadian Orders Analysis (Nov 2023 - Oct 2024)

## 1. Growth Trajectory
* **Initial Phase (Nov-Dec 2023)**: Very low volume, averaging 2-3 orders per day
* **Explosive Growth (Feb 2024)**: Dramatic increase from ~50 to 6,000+ orders per day
* **Maturation (Mar-Oct 2024)**: Stabilized at 8,000-12,000 orders daily

## 2. Key Business Milestones
* **Major Scale Point**: February 7-8, 2024 (2,687 orders/day)
* **Highest Volume Day**: September 25, 2024 (25,045 orders)
* **Highest Revenue Day**: October 14, 2024 ($4.76M)
* **Highest Average Order**: January 13, 2024 ($636.85/order)

## 3. Seasonal Patterns
* **Peak Months**: 
  - February (Initial surge)
  - September (Back to school)
  - October (Pre-holiday shopping)
* **Slower Months**:
  - June-July (Summer lull)
  - Early December (Pre-launch period)

## 4. Weekly Patterns
* **Strongest Days**: Sunday-Tuesday
* **Weakest Days**: Friday-Saturday
* **Revenue Variation**: 30-40% higher on peak days

## 5. Average Order Value (AOV) Trends
* **Overall Range**: $150-$300
* **Initial Period** (Nov-Dec 2023): Highly variable ($14-$576)
* **Stabilized Period** (Post-Feb 2024): $180-$240
* **Notable Spikes**:
  - Special promotions or product launches showing AOV >$300
  - Weekend orders tend to have higher AOV

## 6. Business Performance Phases

### a) Launch Phase (Nov-Jan):
* Low volume: 1-5 orders/day
* Inconsistent AOV
* Testing period characteristics

### b) Growth Phase (Feb):
* Exponential growth
* Order volume increased 100x
* Revenue scaled from thousands to millions

### c) Stabilization Phase (Mar-Oct):
* Consistent daily orders: 8,000-12,000
* Predictable revenue patterns
* Stable AOV around $200-$250

## 7. Key Metrics Summary
* Average Daily Orders (Post-Feb): 9,500
* Average Daily Revenue (Post-Feb): $2.1M
* Typical AOV: $210
* Weekly Revenue: $14.7M (average)
* Monthly Revenue: $63M (average)

## 8. Business Insights

### a) Growth Management:
* Successful scaling from startup to major operation
* Maintained service quality during 100x growth
* Effective operational expansion

### b) Customer Behavior:
* Strong early-week ordering preference
* Higher-value purchases on weekends
* Consistent monthly purchasing patterns

### c) Operational Recommendations:
* Plan for higher capacity early in the week
* Prepare for seasonal peaks (Sept-Oct)
* Consider weekend promotions to boost slower days

## 9. Areas for Further Investigation
* Customer retention rates across growth phases
* Impact of marketing campaigns on daily volumes
* Correlation between promotional activities and AOV
* Geographic distribution within Canada
* Product category performance
* Customer satisfaction metrics during growth periods

    ---------------------

    # Swedish Orders Analysis (Nov 2023 - Oct 2024)

## 1. Growth Trajectory
* **Initial Phase (Nov-Dec 2023)**: Started with minimal volume, 1-8 orders per day
* **First Significant Growth (Mid-Dec 2023)**: Reached 20+ orders/day
* **Major Scale-Up (Jan 2024)**: Dramatic increase culminating in 26,230 orders on Jan 29
* **Stabilization Phase**: Maintained high volume with notable spikes throughout the year

## 2. Key Business Milestones
* **Highest Volume Day**: September 25, 2024 (81,728 orders)
* **Highest Revenue Day**: September 25, 2024 (206.1M SEK)
* **Highest Average Order**: January 28, 2024 (2,361.85 SEK)
* **Peak Week**: Late October 2024 (133.6M SEK on October 27)

## 3. Seasonal Patterns
* **Peak Periods**:
  - Late January (Initial surge)
  - Mid-March (Spring season)
  - Late May (Early summer)
  - Late September (Fall season)
  - Late October (Pre-holiday)
* **Lower Volume Periods**:
  - Early July (Summer holiday)
  - Early August (Holiday season)
  - Early December (Pre-launch)

## 4. Daily Order Value Analysis
* **Initial AOV** (Nov-Dec 2023): Highly variable (500-2,691 SEK)
* **Stabilized AOV** (Post-Feb 2024): 1,200-1,600 SEK
* **Notable Spikes**:
  - September 25: 2,522 SEK AOV
  - May 26: 2,395 SEK AOV
  - January 28-29: >2,000 SEK AOV

## 5. Business Performance Phases

### a) Launch Phase (Nov 2023 - Early Jan 2024)
* Daily orders: 1-20
* Inconsistent order values
* Testing market response

### b) Explosive Growth (Late Jan - Feb 2024)
* Peak of 26,230 orders on January 29
* Dramatic revenue increase
* Strong average order values

### c) Maturation Phase (Mar - Oct 2024)
* Regular daily orders: 10,000-15,000
* Periodic promotional spikes
* More predictable patterns with seasonal variations

## 6. Key Metrics
* **Average Daily Orders** (Post-Feb): ~13,000
* **Typical Daily Revenue**: 15-25M SEK
* **Standard AOV**: ~1,400 SEK
* **Peak Day Performance**: 206.1M SEK (Sept 25)
* **Baseline Daily Orders**: 8,000-12,000

## 7. Operational Insights

### a) Volume Management
* Successful handling of 80x volume increase
* Maintained consistent service during growth
* Effective scaling of operations

### b) Order Patterns
* Higher volumes early in the week
* Lower volumes on weekends
* Major spikes correlating with promotional events

### c) Strategic Observations
* Strong market acceptance in Sweden
* Effective promotional strategy driving peaks
* Successful management of seasonal variations

## 8. Recommendations
1. **Capacity Planning**:
   * Prepare for 80,000+ order days during peak seasons
   * Maintain flexibility for 3-4x normal volume during promotions

2. **Seasonal Strategy**:
   * Strengthen summer period performance
   * Plan for major promotional events in September-October
   * Build on successful spring season momentum

3. **Order Value Optimization**:
   * Investigate high AOV periods for replication
   * Focus on maintaining AOV during high-volume events
   * Consider targeted promotions during lower-volume periods

## 9. Areas for Further Investigation
* Customer retention metrics across growth phases
* Impact of Swedish market preferences on AOV
* Effectiveness of promotional strategies
* Regional distribution within Sweden
* Cart composition during high AOV periods
* Correlation between volume and AOV
* Impact of Swedish holidays on ordering patterns
