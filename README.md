# 🚚 Logistics Optimization for Delivery Routes – Flipkart

A SQL-based logistics analysis project on Flipkart delivery data, covering data cleaning, delay analysis, route optimization, warehouse performance, agent tracking, shipment analytics, and advanced KPI reporting.

---

## 📁 Project Structure

```
flipkart-logistics-optimization/
│
├── eBay.csv                        # Raw dataset (orders, routes, warehouses, agents)
├── sqlproject.sql                  # Complete SQL analysis script
└── README.md
```

---

## 🗄️ Database Tables

| Table | Description |
|---|---|
| `Orders` | Order records with dates, route, warehouse, and agent info |
| `Routes` | Route details — distance, travel time, traffic delay |
| `Warehouses` | Warehouse info and average processing time |
| `DeliveryAgents` | Agent details including average speed |
| `ShipmentTracking` | Checkpoint logs with delay reasons and delay minutes |
| `Route_Performance` | Pre-computed route metrics view |

---

## ✅ Tasks Overview

### Task 1 – Data Cleaning & Preparation
- No duplicate `Order_ID` records found
- No NULL values in `Traffic_Delay_Min` — no replacement needed
- All date columns (`Order_Date`, `Actual_Delivery_Date`) already in `YYYY-MM-DD` ISO format
- Verified no `Actual_Delivery_Date` precedes `Order_Date` — all records valid

### Task 2 – Delivery Delay Analysis
- Added `Delivery_Delay_Days` column using `DATEDIFF(Actual_Delivery_Date, Order_Date)`
- Identified **Top 10 delayed routes** by average delay days
- Used `RANK() OVER (PARTITION BY Warehouse_ID)` to rank orders by delay within each warehouse
- Key finding: Routes **RT_02** and **RT_15** showed the longest delays due to traffic and processing issues

### Task 3 – Route Optimization Insights
- Computed per-route metrics: avg delivery time, avg traffic delay, distance-to-time efficiency ratio
- Identified **3 worst efficiency routes** from `Route_Performance` table
- Filtered routes with **>20% delayed shipments**
- Recommended optimization for **RT_02, RT_15, RT_16**: dynamic traffic-aware scheduling, off-peak dispatch, workload redistribution

### Task 4 – Warehouse Performance
- Found **top 3 warehouses** with highest average processing time
- Calculated total vs. delayed shipments per warehouse with delay percentage
- Used **CTEs** to identify bottleneck warehouses exceeding the global average processing time
- Ranked warehouses by average delivery delay using `RANK() OVER`
- Key finding: **WH_08** and **WH_07** showed highest processing times and delay rates

### Task 5 – Delivery Agent Performance
- Ranked agents per route by on-time delivery % using `RANK() OVER (PARTITION BY Route_ID)`
- Flagged agents with **on-time delivery % < 80%**
- Used **UNION ALL with subqueries** to compare avg speed of top 5 vs. bottom 5 agents
- Recommendations: targeted training, workload balancing, real-time navigation tools, incentive programs

### Task 6 – Shipment Tracking Analytics
- Extracted **last checkpoint and timestamp** per order using `MAX(Checkpoint_Time)`
- Identified **top 5 most common delay reasons** (excluding NULL and 'None')
- Found orders with **more than 2 delayed checkpoints**
- Key finding: Traffic congestion and warehouse delays were the most frequent delay causes

### Task 7 – Advanced KPI Reporting
- Computed **average delivery delay per region** (grouped by `Routes.Start_Location`)
- Calculated **on-time delivery % per region** using `CASE WHEN` logic
- Analyzed **average traffic delay per route** to identify most congestion-prone corridors

---

## 🛠️ Tech Stack

- **Language:** SQL (MySQL)
- **Concepts Used:** Joins, Aggregations, Window Functions (`RANK`, `PARTITION BY`), CTEs, Subqueries, `DATEDIFF`, `UNION ALL`, `CASE WHEN`

---

## ▶️ How to Run

1. Import the dataset into a MySQL database named `sql_project`
2. Open `sqlproject.sql` in MySQL Workbench or any MySQL client
3. Run tasks sequentially — Task 1 must run before Task 2 (adds `Delivery_Delay_Days` column)

---

## 💡 Key Findings

- Routes RT_02, RT_15, and RT_16 are the most critical for optimization
- WH_08 and WH_07 are bottleneck warehouses with the highest processing times
- Multiple delivery agents recorded on-time rates below 80%, indicating training gaps
- Traffic congestion is the most frequent root cause of shipment delays
- All orders had `Actual_Delivery_Date > Order_Date`, meaning 100% of shipments experienced some delay
