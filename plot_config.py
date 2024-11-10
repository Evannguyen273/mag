mpl.style.use("ggplot")
mpl.rcParams["figure.figsize"] = (20, 5)
mpl.rcParams["axes.facecolor"] = "white"
mpl.rcParams["axes.grid"] = True
mpl.rcParams["grid.color"] = "lightgray"
mpl.rcParams["axes.prop_cycle"] = colors
mpl.rcParams["axes.linewidth"] = 1
mpl.rcParams["xtick.color"] = "black"
mpl.rcParams["ytick.color"] = "black"
mpl.rcParams["font.size"] = 13
mpl.rcParams["figure.titlesize"] = 20
mpl.rcParams["figure.dpi"] = 100
mpl.rcParams["legend.fontsize"] = 10
mpl.rcParams['figure.dpi'] = 100
mpl.rcParams['xtick.labelsize'] = 10
mpl.rcParams['ytick.labelsize'] = 10
mpl.rcParams['axes.labelsize'] = 12




1- barplot
import pandas as pd
import matplotlib.pyplot as plt

# Assuming your SQL query results are in a DataFrame called 'df'
# If not, first run your query and store results in df

# Create figure and axis
fig, ax1 = plt.subplots(figsize=(12, 6))

# Create secondary y-axis
ax2 = ax1.twinx()

# Plot bar chart for total deliveries on primary y-axis
bars = ax1.bar(df['deliverytype'], 
               df['total_deliveries'], 
               color='skyblue', 
               alpha=0.7,
               width=0.5)

# Plot line graphs for percentages on secondary y-axis
line1 = ax2.plot(range(len(df)), 
                 df['on_time_percentage'], 
                 'ro-', 
                 label='On-time %', 
                 linewidth=2,
                 marker='o')
line2 = ax2.plot(range(len(df)), 
                 df['failure_rate'], 
                 'go-', 
                 label='Failure %', 
                 linewidth=2,
                 marker='o')

# Customize primary y-axis (total deliveries)
ax1.set_xlabel('Delivery Type')
ax1.set_ylabel('Total Deliveries', color='skyblue', fontsize=10)
ax1.tick_params(axis='y', labelcolor='skyblue')

# Customize secondary y-axis (percentages)
ax2.set_ylabel('Percentage (%)', color='red', fontsize=10)
ax2.tick_params(axis='y', labelcolor='red')

# Set y-axis ranges for percentages (0-100)
ax2.set_ylim(0, 100)

# Rotate x-axis labels for better readability
plt.xticks(range(len(df)), df['deliverytype'], rotation=45, ha='right')

# Add title
plt.title('Delivery Performance by Type', pad=20, fontsize=12)

# Add value labels on bars
for bar in bars:
    height = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2., height,
             f'{int(height):,}',
             ha='center', va='bottom',
             fontsize=9)

# Add value labels for lines
for i in range(len(df)):
    ax2.text(i, df['on_time_percentage'].iloc[i], 
             f"{df['on_time_percentage'].iloc[i]:.1f}%",
             ha='center', va='bottom', color='red',
             fontsize=9)
    ax2.text(i, df['failure_rate'].iloc[i], 
             f"{df['failure_rate'].iloc[i]:.1f}%",
             ha='center', va='top', color='green',
             fontsize=9)

# Combine legends
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax2.legend(lines1 + lines2, ['Total Deliveries'] + labels2, 
          loc='upper right', bbox_to_anchor=(1.15, 1))

# Add grid for percentage axis
ax2.grid(True, alpha=0.3)

# Adjust layout to prevent label cutoff
plt.tight_layout()

# Show plot
plt.show()

# Print summary statistics
print("\nSummary Statistics:")
print(f"Total Deliveries: {df['total_deliveries'].sum():,}")
print(f"Average On-time Rate: {df['on_time_percentage'].mean():.1f}%")
print(f"Average Failure Rate: {df['failure_rate'].mean():.1f}%")
print(f"Best Performing Delivery Type: {df.loc[df['on_time_percentage'].idxmax(), 'deliverytype']}")
print(f"Worst Performing Delivery Type: {df.loc[df['on_time_percentage'].idxmin(), 'deliverytype']}")
