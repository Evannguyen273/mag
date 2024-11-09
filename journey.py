import pandas as pd
import numpy as np
from datetime import datetime
import seaborn as sns
import matplotlib.pyplot as plt

class EcommerceAnalyzer:
    def __init__(self, df):
        """
        Initialize with a pandas DataFrame containing e-commerce data
        """
        self.df = df
        # Convert timestamp columns to datetime
        self.df['orderdate_timestamp'] = pd.to_datetime(self.df['orderdate_timestamp'])
        self.df['shippingdate_timestamp'] = pd.to_datetime(self.df['shippingdate_timestamp'])
        self.df['delivery_date'] = pd.to_datetime(self.df['delivery_date'])
        
        # Convert flag columns to boolean for easier analysis
        self._convert_flags_to_boolean()

    def _convert_flags_to_boolean(self):
        """
        Convert Y/N flags to boolean and 1/0 delivery mode to boolean
        """
        flag_columns = ['is_return_flag', 'is_short_pick', 'is_zero_pick', 
                       'is_on_time', 'is_delivery_failure']
        
        for col in flag_columns:
            if col in self.df.columns:
                self.df[col] = self.df[col].eq('Y')
        
        # Convert delivery mode to boolean (1 = True, 0 = False)
        if 'deliverymode' in self.df.columns:
            self.df['deliverymode'] = self.df['deliverymode'].eq('1')

    def delivery_performance_analysis(self):
        """
        Analyze delivery performance metrics
        """
        delivery_metrics = self.df.groupby('deliverytype').agg({
            'orderid': 'count',
            'is_on_time': 'mean',
            'consignment_deliverycost': 'mean',
            'is_delivery_failure': 'mean',
            'deliverymode': 'mean'  # Proportion of express deliveries
        }).reset_index()
        
        delivery_metrics.columns = ['delivery_type', 'total_orders', 'on_time_rate', 
                                  'avg_delivery_cost', 'failure_rate', 'express_delivery_rate']
        
        # Convert rates to percentages
        rate_columns = ['on_time_rate', 'failure_rate', 'express_delivery_rate']
        delivery_metrics[rate_columns] = delivery_metrics[rate_columns] * 100
        
        return delivery_metrics

    def product_category_analysis(self):
        """
        Analyze product category performance
        """
        category_metrics = self.df.groupby(['product_group_name', 'product_type_name']).agg({
            'orderid': 'nunique',
            'product_price': ['count', 'mean'],
            'is_return_flag': 'mean',
            'deliverymode': 'mean'
        }).reset_index()
        
        category_metrics.columns = ['product_group', 'product_type', 'unique_orders', 
                                  'total_items', 'avg_price', 'return_rate', 'express_delivery_rate']
        
        # Convert rates to percentages
        category_metrics[['return_rate', 'express_delivery_rate']] *= 100
        return category_metrics

    def warehouse_performance(self):
        """
        Analyze warehouse picking performance
        """
        warehouse_metrics = self.df.groupby('warehouseid').agg({
            'orderid': 'count',
            'is_short_pick': 'mean',
            'is_zero_pick': 'mean',
            'is_delivery_failure': 'mean'
        }).reset_index()
        
        warehouse_metrics.columns = ['warehouse_id', 'total_items', 
                                   'short_pick_rate', 'zero_pick_rate', 'delivery_failure_rate']
        
        # Convert rates to percentages
        rate_columns = ['short_pick_rate', 'zero_pick_rate', 'delivery_failure_rate']
        warehouse_metrics[rate_columns] = warehouse_metrics[rate_columns] * 100
        return warehouse_metrics

    def generate_summary_report(self):
        """
        Generate a comprehensive summary report
        """
        summary = {
            'total_orders': self.df['orderid'].nunique(),
            'total_items': len(self.df),
            'avg_order_value': self.df.groupby('orderid')['product_price'].sum().mean(),
            'return_rate': self.df['is_return_flag'].mean() * 100,
            'on_time_delivery_rate': self.df['is_on_time'].mean() * 100,
            'short_pick_rate': self.df['is_short_pick'].mean() * 100,
            'zero_pick_rate': self.df['is_zero_pick'].mean() * 100,
            'delivery_failure_rate': self.df['is_delivery_failure'].mean() * 100,
            'express_delivery_rate': self.df['deliverymode'].mean() * 100,
            'top_product_groups': self.df['product_group_name'].value_counts().head(),
            'top_delivery_types': self.df['deliverytype'].value_counts().head()
        }
        return summary

    def delivery_mode_analysis(self):
        """
        Analyze performance metrics by delivery mode
        """
        mode_metrics = self.df.groupby('deliverymode').agg({
            'orderid': 'count',
            'consignment_deliverycost': 'mean',
            'is_on_time': 'mean',
            'is_delivery_failure': 'mean',
            'is_return_flag': 'mean'
        }).reset_index()
        
        mode_metrics.columns = ['is_express', 'total_orders', 'avg_delivery_cost',
                              'on_time_rate', 'failure_rate', 'return_rate']
        
        # Convert rates to percentages
        rate_columns = ['on_time_rate', 'failure_rate', 'return_rate']
        mode_metrics[rate_columns] = mode_metrics[rate_columns] * 100
        return mode_metrics

    def plot_delivery_performance(self):
        """
        Create visualizations for delivery performance
        """
        plt.figure(figsize=(15, 6))
        
        # Time series of delivery performance
        daily_metrics = self.df.resample('D', on='orderdate_timestamp').agg({
            'is_on_time': 'mean',
            'is_delivery_failure': 'mean',
            'deliverymode': 'mean'
        }) * 100
        
        daily_metrics.plot(title='Daily Delivery Performance Metrics')
        plt.ylabel('Percentage')
        plt.xlabel('Date')
        plt.legend(['On-time Rate', 'Failure Rate', 'Express Delivery Rate'])
        return plt

# Example usage:
"""
# Load your data
df = pd.read_csv('your_data.csv')

# Initialize analyzer
analyzer = EcommerceAnalyzer(df)

# Get various analyses
delivery_metrics = analyzer.delivery_performance_analysis()
product_metrics = analyzer.product_category_analysis()
warehouse_metrics = analyzer.warehouse_performance()
mode_metrics = analyzer.delivery_mode_analysis()
summary_report = analyzer.generate_summary_report()

# Create visualization
analyzer.plot_delivery_performance()
plt.show()
"""
