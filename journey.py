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

    def delivery_performance_analysis(self):
        """
        Analyze delivery performance metrics
        """
        delivery_metrics = self.df.groupby('deliverytype').agg({
            'orderid': 'count',
            'is_on_time': lambda x: (x == 'Yes').mean(),
            'consignment_deliverycost': 'mean',
            'is_delivery_failure': 'sum'
        }).reset_index()
        
        delivery_metrics.columns = ['delivery_type', 'total_orders', 'on_time_rate', 
                                  'avg_delivery_cost', 'failed_deliveries']
        return delivery_metrics

    def product_category_analysis(self):
        """
        Analyze product category performance
        """
        category_metrics = self.df.groupby(['product_group_name', 'product_type_name']).agg({
            'orderid': 'nunique',
            'product_price': ['count', 'mean'],
            'is_return_flag': lambda x: (x == 'Yes').sum()
        }).reset_index()
        
        category_metrics.columns = ['product_group', 'product_type', 'unique_orders', 
                                  'total_items', 'avg_price', 'returns']
        category_metrics['return_rate'] = (category_metrics['returns'] / 
                                         category_metrics['total_items'] * 100)
        return category_metrics

    def geographic_analysis(self):
        """
        Analyze geographic distribution and performance
        """
        geo_metrics = self.df.groupby(['country', 'town']).agg({
            'orderid': 'nunique',
            'consignment_deliverycost': 'mean',
            'is_on_time': lambda x: (x == 'No').sum(),
            'is_return_flag': lambda x: (x == 'Yes').sum()
        }).reset_index()
        
        geo_metrics.columns = ['country', 'town', 'total_orders', 
                             'avg_delivery_cost', 'delayed_deliveries', 'returns']
        return geo_metrics

    def warehouse_performance(self):
        """
        Analyze warehouse picking performance
        """
        warehouse_metrics = self.df.groupby('warehouseid').agg({
            'orderid': 'count',
            'is_short_pick': lambda x: (x == 'Yes').sum(),
            'is_zero_pick': lambda x: (x == 'Yes').sum()
        }).reset_index()
        
        warehouse_metrics.columns = ['warehouse_id', 'total_items', 
                                   'short_picks', 'zero_picks']
        warehouse_metrics['short_pick_rate'] = (warehouse_metrics['short_picks'] / 
                                              warehouse_metrics['total_items'] * 100)
        warehouse_metrics['zero_pick_rate'] = (warehouse_metrics['zero_picks'] / 
                                             warehouse_metrics['total_items'] * 100)
        return warehouse_metrics

    def fashion_trend_analysis(self):
        """
        Analyze fashion trends and color preferences
        """
        fashion_metrics = self.df.groupby(['colour_group_name', 'product_group_name']).agg({
            'orderid': 'nunique',
            'product_price': ['count', 'mean'],
            'is_return_flag': lambda x: (x == 'Yes').sum()
        }).reset_index()
        
        fashion_metrics.columns = ['color_group', 'product_group', 'unique_orders', 
                                 'total_items', 'avg_price', 'returns']
        fashion_metrics['return_rate'] = (fashion_metrics['returns'] / 
                                        fashion_metrics['total_items'] * 100)
        return fashion_metrics

    def delivery_time_analysis(self):
        """
        Analyze delivery times and processing times
        """
        self.df['processing_time'] = (self.df['shippingdate_timestamp'] - 
                                    self.df['orderdate_timestamp']).dt.total_seconds() / 86400
        self.df['delivery_time'] = (self.df['delivery_date'] - 
                                  self.df['shippingdate_timestamp']).dt.total_seconds() / 86400
        
        time_metrics = self.df.groupby('deliverytype').agg({
            'processing_time': ['mean', 'min', 'max', 'median'],
            'delivery_time': ['mean', 'min', 'max', 'median']
        }).reset_index()
        
        return time_metrics

    def generate_summary_report(self):
        """
        Generate a comprehensive summary report
        """
        summary = {
            'total_orders': self.df['orderid'].nunique(),
            'total_items': len(self.df),
            'avg_order_value': self.df.groupby('orderid')['product_price'].sum().mean(),
            'return_rate': (self.df['is_return_flag'] == 'Yes').mean() * 100,
            'on_time_delivery_rate': (self.df['is_on_time'] == 'Yes').mean() * 100,
            'top_product_groups': self.df['product_group_name'].value_counts().head(),
            'top_colors': self.df['colour_group_name'].value_counts().head()
        }
        return summary

# Example usage:
"""
# Load your data
df = pd.read_csv('your_data.csv')

# Initialize analyzer
analyzer = EcommerceAnalyzer(df)

# Get various analyses
delivery_metrics = analyzer.delivery_performance_analysis()
product_metrics = analyzer.product_category_analysis()
geo_metrics = analyzer.geographic_analysis()
warehouse_metrics = analyzer.warehouse_performance()
fashion_metrics = analyzer.fashion_trend_analysis()
delivery_times = analyzer.delivery_time_analysis()
summary_report = analyzer.generate_summary_report()
"""
