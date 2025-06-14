# Retail Sales Analysis with SQL

This project simulates a complete sales analysis for **Extreme Sport HOUSE**, a mountain and adventure gear distributor. Using real-world business logic and **MySQL**, this analysis covers the company's retail performance across multiple sales channels and store locations. 

The goal is to clean and transform raw sales data, analyze key business metrics, identify top-performing products, and develop data-driven recommendations — all using MYSQL.

# Business Context

**Extreme Sport HOUSE** distributes technical gear for trekking, mountaineering, climbing, and outdoor adventures. The company operates through physical stores, online channels, and external retailers. This analysis focuses on data from **2020 to 2022**, offering insights to support decision-making in product performance, client segmentation, and sales strategies.


# Key Highlights

-  Cleaned and aggregated transactional sales data
-  Built relationships between fact and dimension tables
-  Created a sales order logic using SQL views
-  Calculated key performance indicators (KPIs)
- Analyzed sales by channel, region, and product category
- Identified outliers and top revenue-generating items
-  Segmented customers using RFM-style metrics
-  Developed a basic recommender system using product pairing


# Database Structure

- `ventas` (raw sales data)
- `ventas_agr` (aggregated fact table)
- `productos` (product dimension)
- `tiendas` (store dimension)
- `canales` (sales channel dimension)
- `v_ventas_agr_pedido` (view with unique order IDs)
- `recomendador` (table for product-product relationships)


##  Sprint-Based Approach

| Sprint Week | Focus Area                        | Description |
|-------------|-----------------------------------|-------------|
| Task 1      | Data Cleaning & Aggregation       | Remove duplicates, format dates, and create a clean fact table. |
| Task 2      | Database Structuring              | Add keys and relationships; create sales order view. |
| Task 3      | KPIs & Business Insights          | Channel performance, top clients, and sales trends. |
| Task 4      | Product & Margin Analysis         | Top products by margin and discount outliers. |
| Task 5      | Client Segmentation & Reactivation| Segment stores and identify inactive clients. |
| Task 6      | Product Recommender System        | Recommend products based on co-purchase patterns. |


## Tools & Technologies

- **SQL / MySQL**
- SQL Window Functions
- CTEs (Common Table Expressions)
- Views and Aggregations
- Percentiles and Ranking
- Business Metrics and Logic Segmentation
- 
# Data Model Diagram

Below is the simplified data model used in this analysis:

[Data Model](data_model.png)
