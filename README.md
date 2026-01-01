# Retail End-to-End Business Intelligence Solution (SQL-PowerBI)


![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-Data_Warehouse_and_Analysis-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-DAX_and_Visualization-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Architecture](https://img.shields.io/badge/Architecture-Galaxy_Schema-blue?style=for-the-badge)

## 📊 Overview

This project is an end-to-end business intelligence solution analyzing 3 years of retail performance data (2023-2025) using **MS SQL Server** and **Power BI**. The dashboard connects **Supply Chain efficiency** with **Commercial Profitability** and **Customer Loyalty (RFM)** to provide a 360-degree view of business health.

The solution demonstrates the full data lifecycle: extracting 3NF transactional data, modeling it into a **Galaxy Schema** in SQL Server, and visualizing complex logic like Market Basket Analysis and Churn Risk in Power BI.




---

## 🚀 Business Impact & Key Insights

* **Identified Unrealized Revenue Opportunities:** Uncovered unrealized revenue by analyzing items frequently bought together and understanding upselling opportunities.
* **Risk Mitigation:** Flagged specific suppliers with higher lead times to prevent stockouts.
* **Customer Segmentation:** Segmented the user base into 4 actionable groups (**VIP, Loyal, At-Risk-Churning, and Regular**) using RFM analysis.
* **Profit Optimization:** Identified negative-margin transactions and "unrealized revenue" opportunities.

---


## 🛠️ Tech Stack & Architecture

* **Database:** Microsoft SQL Server
* **ETL/Modeling:** SQL Views, CTEs, and 3NF to Galaxy Schema Transformation
* **Visualization:** Power BI Desktop & Service
* **Analytics:** DAX (Time Intelligence, Semi-Additive Measures), What-If Parameters

## 🛠️ Data Architecture & Modeling

### The Engineering Pipeline (SQL Server)
* **Source:** Normalized 3NF data in Microsoft SQL Server (Data Warehouse)
* **Modeling Strategy:** Transformed into a **Galaxy Schema** (Gold Layer) to support complex multi-process reporting.
* **Fact Tables:** `fct_sales`, `fct_inventory`, `fct_purchasing`.
* **Dimension Tables:** `dim_date`, `dim_customer`, `dim_products`, `dim_store`, `dim_supplier`, `security_mapping`.

---
## 💻 SQL Analytics & Reporting Modules

Before importing data into Power BI, extensive analytical views were engineered directly in SQL Server:

1.  **Customer Intelligence:**
    * **Cohort Analysis:** Tracking customer retention over time.
    * **RFM Analysis:** Recency, Frequency, Monetary scoring.
    * **Customer Segmentation:** Grouping customers for targeted marketing.
    
  
    <p><img width="1917" height="1020" alt="Cohort Analysis" src="https://github.com/user-attachments/assets/0aed88c3-1265-46e0-b74e-dab6937eafbb" /></p>

    <img width="1918" height="1017" alt="Customer RFM and Churn Analysis" src="https://github.com/user-attachments/assets/2ed7bf62-2373-4117-907f-8ffb3b5e54d9" />


2.  **Product & Sales Logic:**
    * **Market Basket Analysis:** Identifying products frequently "Bought Together".
    * **Loss-making Products:** Identifying SKUs with negative margins.
    * **Product Returns:** Analysis of return rates by category.

3.  **Operational Performance:**
    * **Supply Chain:** Shipment delays and Supplier performance analysis.
    * **Monthly KPI Dashboards:** Aggregated Orders, Customers, Revenue, and AOV.
    * **Benchmarking:** Category-wise, Store-wise, and **Year-over-Year (YoY)** analysis.
  
      <img width="1918" height="1018" alt="Monthly KPI Score card and Profits" src="https://github.com/user-attachments/assets/c04c47c5-3044-4bb7-b9cf-4e9c7c833962" />




---



## 📈 Power BI Desktop Report

The report is divided into 5 strategic views:

### 1. Executive Overview
* **KPIs:** Total Revenue, Avg Lead Time, Inventory Current Stock, Total COGS, Total Profit.
* **Visuals:** Revenue Trend Line (2023-25), Store-wise Revenue (Bar Chart with Drill-through).
* **UX:** Date Slicer, Page Navigation.

<img width="1322" height="741" alt="Executive Overview" src="https://github.com/user-attachments/assets/f5c29c15-a71b-4c5a-a68a-58d732e9e6a9" />


### 2. YoY Comparison
* **Focus:** Year-over-Year Matrix analysis.
* **Interaction:** 3 Slicers for deep diving: Store, Brand, and Category.

### 3. Business Insights
* **Scatter Charts:**
    1.  Revenue vs. Time to Sell.
    2.  Profit vs. Revenue.
    * *UX Feature:* Charts overlap and are toggleable using **Bookmarks**.
* **Matrix:** Product-level breakdown of Revenue, Gross Profit, Profit %, and Days to Sell.
* **Visual:** Customer Segmentation Bar Chart.

### 4. Product Segmentation (Market Basket)
* **Focus:** Cross-selling opportunities.
* **Matrix:** Analyzes `Product` vs `Orders with Both` to calculate **Attachment Rate** and **Unrealized Revenue**.

### 5. Customer Intelligence (RFM & Churn)
* **KPIs:** Avg Order Value, VIP Customer Count, Churn Risk Revenue.
* **Matrix:** Detailed RFM and Churn analysis.
* **Slicers:** Date, State, Customer Segment.

---

## Mobile Layout
*Responsive design for warehouse staff to check inventory on the floor.*

<img width="477" height="742" alt="Power Bi Mobile" src="https://github.com/user-attachments/assets/2fc70f74-b624-4163-8412-0f5c07b9c058" />



---



## 📈 Power BI Service Dashboard and Alerts 

*Cloud deployment with automated data alerts for critical KPIs.*

<p><img width="1912" height="1079" alt="Power BI Service Dashboard" src="https://github.com/user-attachments/assets/4bbf767c-9496-48c9-ac93-a35ee4e89432" /></p>  

<p><img width="1917" height="968" alt="Power BI Dashboard Alert" src="https://github.com/user-attachments/assets/46e38e7b-8c93-4d2f-98b7-a9068bee56c7" /></p>



---

### Operational Reporting (Power BI Paginated Report)
* **Tool:** Power BI Report Builder.
* **Objective:** Enable warehouse managers to print "pixel-perfect" stock manifests for physical inventory checks.
* **Key Features:**
    * **Parameters:** Dynamic "Low Stock Threshold" allowing users to filter urgency (e.g., items < 50 units).
    * **Grouping:** Hierarchical layout (Store > Category > Product) for logical warehouse navigation.
    * **Logic:** Uses SQL aggregation `SUM(quantity_change)` to calculate real-time stock levels from transactional tables.
* **Output Preview:**
<img width="598" height="772" alt="paginated report" src="https://github.com/user-attachments/assets/72ee4023-4dd3-4390-8922-1f0d3dd2299e" />


## ✅ Skills Demonstrated

- [x] **Advanced Data Modeling:** Medallion Architecture, Galaxy Schema design with multiple Fact tables.
- [x] **SQL Analytics:** Cohort Analysis, Basket Analysis, and KPI generation.
- [x] **Advanced DAX:** Attachment Rates, Churn Risk logic, Unrealized Revenue.
- [x] **Visual Interaction:** Bookmarks for chart toggling, Drill-throughs, Page Navigation.
- [x] **Security:** Row Level Security (RLS) using mapping tables.

---













