-- Basic relationship query
SELECT DISTINCT
    garment_group_name,
    division_name,
    section_name,
    index_group_name,
    index_description,
    customer_group_name
FROM tableA
ORDER BY 
    customer_group_name,
    division_name,
    section_name,
    index_group_name,
    index_description,
    garment_group_name;

-- Count of items in each relationship
WITH relationship_counts AS (
    SELECT 
        customer_group_name,
        division_name,
        section_name,
        index_group_name,
        index_description,
        garment_group_name,
        COUNT(*) as item_count
    FROM tableA
    GROUP BY 
        customer_group_name,
        division_name,
        section_name,
        index_group_name,
        index_description,
        garment_group_name
)
SELECT *
FROM relationship_counts
ORDER BY item_count DESC;




--------------
  import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

# Read the data
df = pd.read_csv('category_data.csv')

# Create a function to visualize the hierarchy
def visualize_hierarchy():
    # Create a directed graph
    G = nx.DiGraph()
    
    # Add edges for each level of hierarchy
    for _, row in df.iterrows():
        # Customer Group -> Division
        G.add_edge(row['customer_group_name'], row['division_name'])
        # Division -> Section
        G.add_edge(row['division_name'], row['section_name'])
        # Section -> Index Group
        G.add_edge(row['section_name'], row['index_group_name'])
        # Index Group -> Index Description
        G.add_edge(row['index_group_name'], row['index_description'])
        # Index Description -> Garment Group
        G.add_edge(row['index_description'], row['garment_group_name'])

    # Create the layout
    pos = nx.spring_layout(G)
    
    # Draw the graph
    plt.figure(figsize=(20, 12))
    nx.draw(G, pos, with_labels=True, node_color='lightblue', 
            node_size=2000, font_size=8, arrows=True)
    plt.title("Product Category Hierarchy")
    plt.show()

# Print hierarchy statistics
print("Category Hierarchy Analysis:")
print("\nUnique values at each level:")
print(f"Customer Groups: {df['customer_group_name'].nunique()}")
print(f"Divisions: {df['division_name'].nunique()}")
print(f"Sections: {df['section_name'].nunique()}")
print(f"Index Groups: {df['index_group_name'].nunique()}")
print(f"Index Descriptions: {df['index_description'].nunique()}")
print(f"Garment Groups: {df['garment_group_name'].nunique()}")

# Show the hierarchical structure
print("\nHierarchy Structure:")
for customer_group in df['customer_group_name'].unique():
    print(f"\nCustomer Group: {customer_group}")
    divisions = df[df['customer_group_name'] == customer_group]['division_name'].unique()
    for division in divisions:
        print(f"  └─ Division: {division}")
        sections = df[df['division_name'] == division]['section_name'].unique()
        for section in sections:
            print(f"     └─ Section: {section}")
            index_groups = df[df['section_name'] == section]['index_group_name'].unique()
            for index_group in index_groups[:3]:  # Limit to first 3 for brevity
                print(f"        └─ Index Group: {index_group}")
                index_descs = df[df['index_group_name'] == index_group]['index_description'].unique()
                for index_desc in index_descs[:2]:  # Limit to first 2 for brevity
                    print(f"           └─ Index Description: {index_desc}")
                    garment_groups = df[df['index_description'] == index_desc]['garment_group_name'].unique()
                    for garment_group in garment_groups[:2]:  # Limit to first 2 for brevity
                        print(f"              └─ Garment Group: {garment_group}")

visualize_hierarchy()
