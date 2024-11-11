sqlCopy-- Updated hierarchy query
SELECT DISTINCT
    customer_group_name,
    division_name,
    section_name,
    index_group_name,
    index_description,
    product_group_name,
    garment_group_name
FROM tableA
ORDER BY 
    customer_group_name,
    division_name,
    section_name,
    index_group_name,
    index_description,
    product_group_name,
    garment_group_name;


------
-- Count of combinations
WITH hierarchy_counts AS (
    SELECT 
        customer_group_name,
        division_name,
        section_name,
        index_group_name,
        index_description,
        product_group_name,
        garment_group_name,
        COUNT(*) as item_count
    FROM tableA
    GROUP BY 
        customer_group_name,
        division_name,
        section_name,
        index_group_name,
        index_description,
        product_group_name,
        garment_group_name
)
SELECT *
FROM hierarchy_counts
ORDER BY item_count DESC;










------------

import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

def analyze_product_hierarchy(df):
    print("Complete Product Hierarchy Analysis:")
    print("\nUnique values at each level:")
    print(f"Customer Groups: {df['customer_group_name'].nunique()}")
    print(f"Divisions: {df['division_name'].nunique()}")
    print(f"Sections: {df['section_name'].nunique()}")
    print(f"Index Groups: {df['index_group_name'].nunique()}")
    print(f"Index Descriptions: {df['index_description'].nunique()}")
    print(f"Product Groups: {df['product_group_name'].nunique()}")
    print(f"Garment Groups: {df['garment_group_name'].nunique()}")

    # Analyze relationships
    print("\nRelationship Analysis:")
    for col1, col2 in [
        ('customer_group_name', 'division_name'),
        ('division_name', 'section_name'),
        ('section_name', 'index_group_name'),
        ('index_group_name', 'index_description'),
        ('index_description', 'product_group_name'),
        ('product_group_name', 'garment_group_name')
    ]:
        relationship = df.groupby(col1)[col2].nunique()
        print(f"\n{col1} to {col2}:")
        print(f"Average {col2}s per {col1}: {relationship.mean():.1f}")
        print(f"Max {col2}s per {col1}: {relationship.max()}")

    # Show example hierarchy
    print("\nExample Hierarchy Path:")
    sample = df.iloc[0]
    print(f"Customer Group: {sample['customer_group_name']}")
    print(f"└─ Division: {sample['division_name']}")
    print(f"   └─ Section: {sample['section_name']}")
    print(f"      └─ Index Group: {sample['index_group_name']}")
    print(f"         └─ Index Description: {sample['index_description']}")
    print(f"            └─ Product Group: {sample['product_group_name']}")
    print(f"               └─ Garment Group: {sample['garment_group_name']}")

    # Create visualization
    plt.figure(figsize=(20, 12))
    
    # Create hierarchical layout
    levels = [
        df['customer_group_name'].unique(),
        df['division_name'].unique(),
        df['section_name'].unique(),
        df['index_group_name'].unique(),
        df['index_description'].unique(),
        df['product_group_name'].unique(),
        df['garment_group_name'].unique()
    ]
    
    # Plot as vertical bars showing hierarchy levels
    for i, level in enumerate(levels):
        y = [i] * len(level)
        x = range(len(level))
        plt.scatter(x, y, s=100)
        if i == 0:
            plt.text(-0.5, i, 'Customer Groups', ha='right')
        elif i == 1:
            plt.text(-0.5, i, 'Divisions', ha='right')
        elif i == 2:
            plt.text(-0.5, i, 'Sections', ha='right')
        elif i == 3:
            plt.text(-0.5, i, 'Index Groups', ha='right')
        elif i == 4:
            plt.text(-0.5, i, 'Index Descriptions', ha='right')
        elif i == 5:
            plt.text(-0.5, i, 'Product Groups', ha='right')
        else:
            plt.text(-0.5, i, 'Garment Groups', ha='right')
            
    plt.title('Product Category Hierarchy Levels')
    plt.xlabel('Number of Categories')
    plt.ylabel('Hierarchy Level')
    plt.grid(True, axis='y')
    plt.show()

    # Print common combinations
    print("\nMost Common Category Combinations:")
    combinations = df.groupby([
        'customer_group_name',
        'division_name',
        'section_name',
        'index_group_name',
        'index_description',
        'product_group_name',
        'garment_group_name'
    ]).size().reset_index(name='count')
    
    print(combinations.nlargest(10, 'count'))

# Assuming df is your DataFrame with the category data
# analyze_product_hierarchy(df)
