# Retail Sales & Inventory Analysis with MYSQL

This project simulates a complete sales and inventory analysis for **Extreme Sport House**, a mountain and adventure gear distributor. Using real-world business logic and **MySQL**, this analysis covers the company's retail performance across multiple sales channels and store locations. 

The goal is to clean and transform raw sales data, analyze behavior, classify product performance , and estimate minimum stock needs — all using MYSQL.

# Business Context

**Extreme Sport House** distributes technical gear for trekking, mountaineering, climbing, and outdoor adventures. The company operates through physical stores, online channels, and external retailers. This analysis focuses on data from 2020 to 2023, offering insights to support decision-making in **product performance**, **channel performance**, and **stock management**.


# Key Highlights

-  Cleaned and aggregated transactional sales data
-  Built relationships between fact and dimension tables
-  Created a sales order logic using SQL views
-  Calculated key performance indicators (KPIs)
-  Analyzed sales by channel, region, and product category
-  Identified outliers and top revenue-generating items
-  Classified products using ABC analysis
-  Estimated minimun stock levels based on demand variability


# Database Structure

- `ventas` (raw sales data)
- `ventas_agr` (aggregated fact table)
- `productos` (product dimension)
- `tiendas` (store dimension)
- `canales` (sales channel dimension)


##  Sprint-Based Approach

| Sprint Week | Focus Area                        | Description |
|-------------|-----------------------------------|-------------|
| Task 1      | Data Cleaning & Aggregation       | Remove duplicates, format dates, and create a clean fact table. |
| Task 2      | Database Structuring              | Add keys and relationships; create sales order view. |
| Task 3      | KPIs & Business Insights          | Channel performance, top clients, and sales trends. |
| Task 4      | Product & Margin Analysis         | Top products by margin and discount outliers. |
| Task 5      | ABC Product Classification        | Categorize products into ABC classes based on quantity of sales |
| Task 6      | Stock Minimun Estimation          | Estimate suggested stock levels, using daily demand and standard deviation. |


## Tools & Technologies

- **SQL / MySQL**
- SQL Window Functions
- CTEs (Common Table Expressions)
- Views and Aggregations
- Percentiles and Ranking
- Business Metrics and Logic Segmentation

# Data Model Diagram

Below is the simplified data model used in this analysis:

[Data Model](data_model.png)
