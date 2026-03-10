use sql_project;

select * from orders;
select * from routes;
select * from warehouses;
select * from deliveryagents;
select * from shipmenttracking;
select * from Route_Performance;

-- Task 1.1
-- no duplicate record found
SELECT Order_ID, COUNT(*) AS duplicate_count FROM Orders GROUP BY Order_ID HAVING COUNT(*) > 1;

-- Task 1.2
-- Data Cleaning Step: Handling Missing Traffic_Delay_Min
-- Verified: No NULL values found in Traffic_Delay_Min column.
-- No replacement necessary. Data is already clean.

-- Task 1.3
-- Data Cleaning Step: Date Format Normalization
-- Verified that all date columns (Order_Date, Actual_Delivery_Date) 
-- are already in 'YYYY-MM-DD' ISO format.
-- No conversion or formatting changes required.

-- Task 1.4
-- Verified that no Actual_Delivery_Date is earlier than Order_Date.
-- All records are valid; no corrections required.

-- Task 2.1 Calculate Delivery Delay (in Days)
ALTER TABLE Orders
ADD COLUMN Delivery_Delay_Days INT;

UPDATE Orders
SET Delivery_Delay_Days = DATEDIFF(Actual_Delivery_Date, Order_Date);

select order_id,order_date,actual_delivery_date,delivery_delay_days from orders;

-- Computed difference between Actual_Delivery_Date and Order_Date
-- using DATEDIFF() function.
-- Stored as Delivery_Delay_Days for each order.

-- Task 2.2 Top 10 Delayed Routes by Average Delay Days
SELECT
    Route_ID,
    ROUND(AVG(Delivery_Delay_Days), 2) AS Avg_Delay_Days,
    COUNT(Order_ID) AS Total_Orders
FROM Orders
GROUP BY Route_ID
ORDER BY Avg_Delay_Days DESC
LIMIT 10;

-- Calculated average delivery delay per Route_ID using AVG().
-- Sorted in descending order and extracted top 10 routes.
-- These represent the most delayed routes requiring optimization.

-- Task 2.3 Rank Orders by Delay within Each Warehouse
SELECT
    Warehouse_ID,
    Order_ID,
    Order_Date,
    Actual_Delivery_Date,
    DATEDIFF(Actual_Delivery_Date, Order_Date) AS Delivery_Delay_Days,
    RANK() OVER (
        PARTITION BY Warehouse_ID
        ORDER BY DATEDIFF(Actual_Delivery_Date, Order_Date) DESC
    ) AS Delay_Rank
FROM Orders;

-- Used RANK() OVER (PARTITION BY Warehouse_ID ORDER BY Delivery_Delay DESC)
-- to rank all orders by delay days inside each warehouse.
-- Helps identify the most delayed shipments per warehouse.

-- Task 3.1 Route Performance Metrics
SELECT
    r.Route_ID,
    ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)), 2)              AS Avg_Delivery_Time_Days,
    ROUND(AVG(r.Traffic_Delay_Min), 2)                                       AS Avg_Traffic_Delay_Min,
    ROUND(AVG(r.Distance_KM / NULLIF(r.Average_Travel_Time_Min, 0)), 2)      AS Avg_Distance_Time_Efficiency
FROM Orders o
JOIN Routes r ON o.Route_ID = r.Route_ID
GROUP BY r.Route_ID
ORDER BY Avg_Delivery_Time_Days DESC;

select * from route_performance;

-- Joined Orders and Routes tables on Route_ID.
-- Calculated:
--   • Average Delivery Time (days)
--   • Average Traffic Delay (minutes)
--   • Distance-to-Time Efficiency Ratio (Distance_KM / Avg_Travel_Time_Min)
-- Helps identify routes with longer delivery durations or inefficiencies.

-- Task 3.2 Identify 3 Routes with the Worst Efficiency Ratio
SELECT
    Route_ID,
    Avg_Delivery_Time_Days,
    Avg_Traffic_Delay_Min,
    Avg_Distance_Time_Efficiency
FROM Route_Performance
ORDER BY Avg_Distance_Time_Efficiency ASC
LIMIT 3;

-- Analyzed the Route_Performance table.
-- Ordered by Distance_Time_Efficiency (ascending) and selected top 3 routes.
-- These represent the least efficient routes requiring optimization.

-- Task 3.3 Routes with >20% Delayed Shipments
SELECT
    Route_ID,
    COUNT(Order_ID) AS Total_Orders,
    SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date, Order_Date) > 0 THEN 1 ELSE 0 END) AS Delayed_Orders,
    ROUND(
        (SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date, Order_Date) > 0 THEN 1 ELSE 0 END) 
        / COUNT(Order_ID) * 100.0), 2
    ) AS Delayed_Percentage
FROM Orders
GROUP BY Route_ID
HAVING Delayed_Percentage > 20
ORDER BY Delayed_Percentage DESC;

-- Calculated delayed shipment percentage per Route_ID.
-- Filtered routes having more than 20% of orders delayed.
-- These represent the least reliable routes needing optimization.

-- Task 3.4
-- Based on route performance metrics, Routes RT_02, RT_15, and RT_16 were identified 
-- as the most critical for optimization. These routes recorded the highest average 
-- delayed shipments. Frequent traffic congestion, long travel distances, and uneven 
-- order distribution contribute to recurring inefficiencies. 

-- Recommended actions include re-evaluating route structures, implementing 
-- dynamic traffic-aware scheduling, and balancing workload across alternative 
-- nearby routes. Integrating predictive route optimization tools and adjusting 
-- dispatch times to off-peak hours can further enhance speed and consistency. 
-- and improve overall regional efficiency in future cycles.

-- Task 4.1 Top 3 Warehouses by Average Processing Time
SELECT Warehouse_ID, warehouse_name, Average_Processing_Time_Min
FROM Warehouses
ORDER BY Average_Processing_Time_Min DESC
LIMIT 3;

-- Calculated the average processing time for each warehouse 
-- using the Warehouses table and identified the top 3 with 
-- the highest average processing time.
-- These warehouses may face processing bottlenecks and 
-- require operational improvements.

-- Task 4.2 Total vs. Delayed Shipments per Warehouse
SELECT
    o.Warehouse_ID,
    w.Warehouse_Name AS Warehouse_Name,
    COUNT(o.Order_ID) AS Total_Shipments,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Order_Date) > 0 THEN 1 ELSE 0 END) AS Delayed_Shipments,
    ROUND(
        (SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Order_Date) > 0 THEN 1 ELSE 0 END) * 100.0) 
        / COUNT(o.Order_ID), 2
    ) AS Delayed_Percentage
FROM Orders o
JOIN Warehouses w ON o.Warehouse_ID = w.Warehouse_ID
GROUP BY o.Warehouse_ID, w.warehouse_Name
ORDER BY Delayed_Percentage DESC;

-- Calculated total and delayed shipments for each warehouse 
-- using Orders data. Also computed delayed shipment percentage 
-- to identify warehouses with higher delay ratios.
-- Results highlight warehouses requiring performance improvement.

 -- Task 4.3 Bottleneck Warehouses (CTE)
 WITH WarehouseAvg AS (
  SELECT
    Warehouse_ID,
    warehouse_Name,
    Average_Processing_Time_Min
  FROM Warehouses
),
GlobalAvg AS (
  SELECT AVG(Average_Processing_Time_Min) AS Global_Avg
  FROM WarehouseAvg
)
SELECT
  wa.Warehouse_ID,
  wa.warehouse_Name,
  wa.Average_Processing_Time_Min,
  ga.Global_Avg
FROM WarehouseAvg wa
CROSS JOIN GlobalAvg ga
WHERE wa.Average_Processing_Time_Min > ga.Global_Avg
ORDER BY wa.Average_Processing_Time_Min DESC;

-- Identified warehouses where average processing time > global average.
-- Method: computed per-warehouse avg processing time (from Warehouses or Orders),
-- computed global avg (CTE), and selected warehouses above global avg.

-- Task 4.4 Rank Warehouses by On-Time Delivery Percentage
SELECT
  o.Warehouse_ID,
  w.warehouse_Name AS Warehouse_Name,
  ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)), 2) AS Avg_Delay_Days,
  RANK() OVER (ORDER BY AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)) ASC) AS Rank_OnTimePerformance
FROM Orders o
JOIN Warehouses w ON o.Warehouse_ID = w.Warehouse_ID
GROUP BY o.Warehouse_ID, w.warehouse_Name
ORDER BY Avg_Delay_Days ASC;

-- Verified that all orders in dataset have Actual_Delivery_Date > Order_Date,
-- resulting in 100% delayed shipments for all warehouses.
-- To differentiate performance, warehouses were ranked based on
-- average delivery delay (in days). Lower delay days indicate better efficiency.

-- Task 5.1 Rank Agents by On-Time Delivery % per Route
WITH AgentPerformance AS (
  SELECT
    Route_ID,
    Agent_ID,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN DATE(Actual_Delivery_Date) <= DATE(Order_Date) THEN 1 ELSE 0 END) AS OnTime_Orders,
    ROUND(
      100.0 * SUM(CASE WHEN DATE(Actual_Delivery_Date) <= DATE(Order_Date) THEN 1 ELSE 0 END) / COUNT(*),
      2
    ) AS OnTime_Percentage,
    -- avg delay used as a tie-breaker (lower is better)
    ROUND(AVG(DATEDIFF(Actual_Delivery_Date, Order_Date)), 2) AS Avg_Delay_Days
  FROM Orders
  GROUP BY Route_ID, Agent_ID
)
SELECT
  Route_ID,
  Agent_ID,
  Total_Orders,
  OnTime_Orders,
  OnTime_Percentage,
  Avg_Delay_Days,
  RANK() OVER (
    PARTITION BY Route_ID
    ORDER BY OnTime_Percentage DESC, Avg_Delay_Days ASC, Total_Orders DESC
  ) AS Rank_Within_Route
FROM AgentPerformance
ORDER BY Route_ID, Rank_Within_Route;

-- Aggregated per agent per route: total orders, on-time orders, on-time %.
-- Ranked within each route by on-time % (tie-breakers: lower avg delay, higher volume).

-- Task 5.2 Identify Agents with On-Time Delivery % < 80
SELECT
    Agent_ID,
    Route_ID,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN DATE(Actual_Delivery_Date) <= DATE(Order_Date) THEN 1 ELSE 0 END) AS OnTime_Orders,
    ROUND(
        (SUM(CASE WHEN DATE(Actual_Delivery_Date) <= DATE(Order_Date) THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
        2
    ) AS OnTime_Percentage
FROM Orders
GROUP BY Agent_ID, Route_ID
HAVING OnTime_Percentage < 80
ORDER BY OnTime_Percentage ASC;

-- Calculated total and on-time orders for each agent per route.
-- Filtered results where OnTime_Percentage < 80 to flag low-performing agents.
-- These agents need performance review or additional training.

-- Task 5.3

SELECT 
    'Top 5 Agents' AS Group_Label,
    t.Agent_ID,
    t.ontime_pct AS OnTime_Percentage,
    da.Avg_Speed_KMPH
FROM (
    SELECT 
        Agent_ID,
        ROUND(
            (SUM(CASE WHEN DATE(Actual_Delivery_Date) <= DATE(Order_Date) THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
            2
        ) AS ontime_pct
    FROM Orders
    GROUP BY Agent_ID
    ORDER BY ontime_pct DESC
    LIMIT 5
) AS t
JOIN DeliveryAgents da USING (Agent_ID)

UNION ALL

SELECT 
    'Bottom 5 Agents' AS Group_Label,
    b.Agent_ID,
    b.ontime_pct AS OnTime_Percentage,
    da.Avg_Speed_KMPH
FROM (
    SELECT 
        Agent_ID,
        ROUND(
            (SUM(CASE WHEN DATE(Actual_Delivery_Date) <= DATE(Order_Date) THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
            2
        ) AS ontime_pct
    FROM Orders
    GROUP BY Agent_ID
    ORDER BY ontime_pct ASC
    LIMIT 5
) AS b
JOIN DeliveryAgents da USING (Agent_ID)
ORDER BY Group_Label, OnTime_Percentage DESC;

-- Used two subqueries to find top and bottom 5 agents based on on-time %
-- Combined results using UNION ALL for a single comparison table.
-- Displays Agent_ID, On-Time %, and Avg_Speed_KMPH for performance analysis.

-- Task 5.4: Recommendations for Low-Performing Delivery Agents
-- Analysis showed several agents with On-Time Delivery % below 80%.
-- Suggested strategies:
--   1. Conduct targeted training on route optimization and time management.
--   2. Balance workloads by redistributing congested routes.
--   3. Implement performance feedback dashboards and incentive programs.
--   4. Use real-time navigation and route-optimization tools.
-- Goal: improve on-time performance and overall delivery efficiency.

-- Task 6.1 Last Checkpoint and Time per Order
SELECT
    s.Order_ID,
    s.Checkpoint AS Last_Checkpoint,
    s.Checkpoint_Time AS Last_Checkpoint_Time
FROM ShipmentTracking s
JOIN (
    SELECT 
        Order_ID,
        MAX(CAST(Checkpoint_Time AS DATETIME)) AS Last_Time
    FROM ShipmentTracking
    GROUP BY Order_ID
) latest
  ON s.Order_ID = latest.Order_ID
 AND CAST(s.Checkpoint_Time AS DATETIME) = latest.Last_Time
ORDER BY s.Order_ID;

-- Extracted the most recent checkpoint and timestamp for each order 
-- using MAX(Checkpoint_Time) grouped by Order_ID.
-- Provides the latest shipment tracking status of each order.

-- Task 6.2 Most Common Delay Reasons
SELECT
    Delay_Reason,
    COUNT(*) AS Occurrences
FROM ShipmentTracking
WHERE Delay_Reason IS NOT NULL
  AND LOWER(Delay_Reason) <> 'none'
GROUP BY Delay_Reason
ORDER BY Occurrences DESC
LIMIT 5;

-- Aggregated ShipmentTracking data to count frequency of each Delay_Reason.
-- Excluded 'None' and NULL values.
-- Sorted results by occurrence count to identify top delay causes.

-- Task 6.3 Orders with More Than 2 Delayed Checkpoints
SELECT
    Order_ID,
    COUNT(*) AS Delayed_Checkpoints
FROM ShipmentTracking
WHERE 
    (Delay_Reason IS NOT NULL AND LOWER(Delay_Reason) <> 'none')
    OR (Delay_Minutes > 0)
GROUP BY Order_ID
HAVING COUNT(*) > 2
ORDER BY Delayed_Checkpoints DESC;

-- Counted delay occurrences per Order_ID from ShipmentTracking.
-- Considered a checkpoint delayed if Delay_Reason <> 'None' or Delay_Minutes > 0.
-- Selected orders having more than 2 such delays for detailed analysis.

-- Task 7.1 Average Delivery Delay per Region (Start_Location)
SELECT
  r.Start_Location AS Region,
  ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)), 2) AS Avg_Delay_Days,
  COUNT(o.Order_ID) AS Num_Orders
FROM Orders o
JOIN Routes r ON o.Route_ID = r.Route_ID
GROUP BY r.Start_Location
ORDER BY Avg_Delay_Days DESC;

-- Joined Orders with Routes on Route_ID and computed average delivery delay (days)
-- grouped by Routes.Start_Location. Returned Avg_Delay_Days and number of orders per region.

-- Task 7.2 On-Time Delivery Percentage per Region
SELECT
    r.Start_Location AS Region,
    COUNT(o.Order_ID) AS Total_Deliveries,
    SUM(CASE WHEN DATE(o.Actual_Delivery_Date) <= DATE(o.Order_Date) THEN 1 ELSE 0 END) AS OnTime_Deliveries,
    ROUND(
        (SUM(CASE WHEN DATE(o.Actual_Delivery_Date) <= DATE(o.Order_Date) THEN 1 ELSE 0 END) * 100.0) / COUNT(o.Order_ID),
        2
    ) AS OnTime_Delivery_Percentage
FROM Orders o
JOIN Routes r ON o.Route_ID = r.Route_ID
GROUP BY r.Start_Location
ORDER BY OnTime_Delivery_Percentage DESC;

-- Formula: (Total On-Time Deliveries / Total Deliveries) * 100
-- Used CASE WHEN to count on-time orders (Actual_Delivery_Date <= Order_Date)
-- Joined Orders with Routes on Route_ID, grouped by Start_Location (Region).
-- Helps evaluate regional delivery efficiency and identify improvement areas.

-- Task 7.3 Average Traffic Delay per Route
SELECT
    r.Route_ID,
    r.Start_Location,
    r.End_Location,
    ROUND(AVG(r.Traffic_Delay_Min), 2) AS Avg_Traffic_Delay_Minutes,
    COUNT(o.Order_ID) AS Total_Orders
FROM Routes r
JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location
ORDER BY Avg_Traffic_Delay_Minutes DESC;

-- Joined Orders with Routes using Route_ID.
-- Calculated average Traffic_Delay_Min per route using AVG().
-- Ranked routes by average traffic delay (descending).
-- Identifies most traffic-affected routes for optimization.