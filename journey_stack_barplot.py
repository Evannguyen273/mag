import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import gc  # for garbage collection

def create_stacked_barchart(df, group_col, stack_col, save_path='graphs'):
    """
    Create and save stacked bar chart
    
    Args:
        df: pandas DataFrame
        group_col: column to group by (e.g., 'country')
        stack_col: column to create stacks (e.g., 'department_name')
        save_path: folder to save graphs
    """
    # Create directory if it doesn't exist
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    
    # Create figure
    plt.figure(figsize=(15, 8))
    
    # Create pivot table and calculate percentages
    pivot_data = pd.crosstab(
        index=df[group_col],
        columns=df[stack_col],
        normalize='index'
    ) * 100
    
    # Create stacked bar chart
    ax = pivot_data.plot(kind='bar', stacked=True)
    
    # Customize the chart
    plt.title(f'Distribution of {stack_col} by {group_col}')
    plt.xlabel(group_col)
    plt.ylabel('Percentage')
    plt.legend(title=stack_col, bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tick_params(axis='x', rotation=45)
    plt.grid(False)
    
    # Adjust layout
    plt.tight_layout()
    
    # Save the figure
    filename = f'{group_col}_vs_{stack_col}_distribution.png'
    plt.savefig(os.path.join(save_path, filename), 
                bbox_inches='tight', 
                dpi=300)
    
    # Clear the figure and pivot data
    plt.close()
    del pivot_data
    gc.collect()

# Call function individually for each analysis
# 1. Country vs Department
create_stacked_barchart(cp, 'country', 'department_id')

# 2. Country vs Product Name
create_stacked_barchart(cp, 'country', 'product_name')

# 3. Country vs Product Group
create_stacked_barchart(cp, 'country', 'product_group_name')

# 4. Country vs Sub Index Name (as customer group)
create_stacked_barchart(cp, 'country', 'sub_index_name')

# 5. Country vs Colour Group
create_stacked_barchart(cp, 'country', 'colour_group_name')

# 6. Country vs Sub Index
create_stacked_barchart(cp, 'country', 'sub_index_name')

# 7. Country vs Index Description
create_stacked_barchart(cp, 'country', 'index_description')

# 8. Country vs Index Group
create_stacked_barchart(cp, 'country', 'index_group_name')

# 9. Country vs Section
create_stacked_barchart(cp, 'country', 'section_name')

# 10. Country vs Division
create_stacked_barchart(cp, 'country', 'division_name')

# 11. Country vs Garment Group
create_stacked_barchart(cp, 'country', 'garment_group_name')
