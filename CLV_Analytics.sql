--CLV VALUE

--BASIC CLV

Use AdventureWorksDW2025;

SELECT
CustomerKey,
SalesOrderNumber,
CAST(OrderDate AS DATE) OrderDate,
SalesAmount TotalRevenue,
COUNT(*) OVER(PARTITION BY CustomerKey) TotalOrders,
FIRST_VALUE(CAST(OrderDate AS DATE)) OVER(PARTITION BY CustomerKey ORDER BY OrderDate) FIRSTORDER,
LAST_VALUE(CAST(OrderDate AS DATE)) OVER(PARTITION BY CustomerKey ORDER BY OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LASTORDER,
DATEDIFF(
        DAY,
        FIRST_VALUE(CAST(OrderDate AS DATE)) 
            OVER (PARTITION BY CustomerKey ORDER BY OrderDate),
        LAST_VALUE(CAST(OrderDate AS DATE)) 
            OVER (
                PARTITION BY CustomerKey 
                ORDER BY OrderDate 
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )
    ) AS LifetimeDays
from 
AdventureWorksDW2025.dbo.FactInternetSales

--CLV Segmentation (High / Medium / Low)

SELECT 
*,
CASE
	WHEN Buckets=1 THEN 'High CLV'
	WHEN Buckets=2 THEN 'Medium CLV'
	ELSE 'Low CLV'
END CLV
FROM 
(
SELECT 
CustomerKey,
SUM(SalesAmount) TotalSales,
NTILE(3) OVER(ORDER BY SUM(SalesAmount) DESC) Buckets
FROM 
AdventureWorksDW2025.dbo.FactInternetSales
GROUP BY CustomerKey
)
t

--Churn risk (long inactive customers)

SELECT 
CustomerKey,
FirstOrderDate,
LastOrderDate,
DATEDIFF(DAY, LastOrderDate, CAST(GETDATE() AS DATE)) AS InactiveDays,
CASE
    WHEN DATEDIFF(DAY, LastOrderDate, CAST(GETDATE() AS DATE)) <= 90 THEN 'Active'
    WHEN DATEDIFF(DAY, LastOrderDate, CAST(GETDATE() AS DATE)) BETWEEN 91 AND 180 THEN 'At Risk'
    ELSE 'Churned'
END AS CustomerStatus
FROM 
(
SELECT 
CustomerKey,
MIN(CAST(OrderDate AS DATE)) AS FirstOrderDate,
MAX(CAST(OrderDate AS DATE)) AS LastOrderDate
FROM
AdventureWorksDW2025.dbo.FactInternetSales
GROUP BY CustomerKey
)
t

--Revenue per customer per lifetime day

--Sum of all purchases made by the customer
--Days between first and last purchase
--Total Revenue ÷ Lifetime Days

SELECT 
CustomerKey,
TotalSales,
FirstOrderDate,
LastOrderDate,
DateDifference + 1 AS LifetimeDays,
ROUND(
    TotalSales / NULLIF(DateDifference + 1, 0),
    2
) AS RevenuePerLifetimeDay
FROM 
(
	SELECT 
		CustomerKey,
		ROUND(SUM(SalesAmount),2) TotalSales,
		MIN(CAST(OrderDate AS DATE)) FirstOrderDate,
		MAX(CAST(OrderDate AS DATE)) LastOrderDate,
		DATEDIFF(
			DAY,
			MIN(CAST(OrderDate AS DATE)),
			MAX(CAST(OrderDate AS DATE))
			) DateDifference
	FROM 
		AdventureWorksDW2025.dbo.FactInternetSales
	GROUP BY 
	CustomerKey
)t



