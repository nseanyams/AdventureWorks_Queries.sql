-- Question 1: Top 10 Customers by Revenue. --

SELECT TOP 10
    CONCAT(C.FirstName, ' ', C.MiddleName, ' ', C.LastName) AS FullName,
    A.CountryRegion AS Country,
    A.City AS City,
    SUM(SOD.UnitPrice * SOD.OrderQty) AS Revenue
FROM SalesLT.Customer C
JOIN SalesLT.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
JOIN SalesLT.CustomerAddress CA ON C.CustomerID = CA.CustomerID
JOIN SalesLT.Address A ON CA.AddressID = A.AddressID
JOIN SalesLT.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY 
    C.FirstName, 
    C.MiddleName, 
    C.LastName, 
    A.CountryRegion, 
    A.City
ORDER BY Revenue DESC;


--Question 2: Customer Revenue-Based Segmentation Analysis.--

WITH CustomerRevenue AS (
    SELECT
        C.CustomerID,
        C.CompanyName,
        SUM(SOD.OrderQty * SOD.UnitPrice) AS Revenue
    FROM SalesLT.Customer C
    JOIN SalesLT.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
    JOIN SalesLT.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    GROUP BY C.CustomerID, C.CompanyName
),
RankedRevenue AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY Revenue DESC) AS RevenueSegment
    FROM CustomerRevenue
)
SELECT
    CustomerID,
    CompanyName,
    Revenue,
    CASE RevenueSegment
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
    END AS CustomerSegment
FROM RankedRevenue
ORDER BY Revenue DESC;

-- Question 3: Recent Customer Product Purchase Snapshot.--

-- Step 1: Find the latest order date
WITH LastOrderDate AS (
    SELECT MAX(OrderDate) AS MaxOrderDate
    FROM SalesLT.SalesOrderHeader
),

-- Step 2: Get product details from orders on the last business day
LastDayPurchases AS (
    SELECT
        SOH.CustomerID,
        SOD.ProductID,
        P.Name AS ProductName,
        PC.Name AS CategoryName,
        SOH.OrderDate
    FROM SalesLT.SalesOrderHeader SOH
    JOIN SalesLT.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    JOIN SalesLT.Product P ON SOD.ProductID = P.ProductID
    JOIN SalesLT.ProductCategory PC ON P.ProductCategoryID = PC.ProductCategoryID
    JOIN LastOrderDate LOD ON SOH.OrderDate = LOD.MaxOrderDate
)

-- Final Result
SELECT *
FROM LastDayPurchases
ORDER BY CustomerID, ProductID;

-- Question 4: Customer Revenue Segmentation View Creation. --

CREATE VIEW CustomerSegment AS
SELECT 
    C.CustomerID,
    CONCAT(C.FirstName, ' ', 
           ISNULL(C.MiddleName + ' ', ''), 
           C.LastName) AS FullName,
    SUM(SOD.UnitPrice * SOD.OrderQty) AS Revenue,
    CASE 
        WHEN SUM(SOD.UnitPrice * SOD.OrderQty) >= 10000 THEN 'High'
        WHEN SUM(SOD.UnitPrice * SOD.OrderQty) >= 5000 THEN 'Medium'
        ELSE 'Low'
    END AS Segment
FROM SalesLT.Customer C
JOIN SalesLT.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
JOIN SalesLT.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
GROUP BY 
    C.CustomerID,
    C.FirstName, 
    C.MiddleName, 
    C.LastName;

	--Question 5: Best Selling Products per Category--
	
	WITH ProductRevenue AS (
    SELECT 
        P.ProductID,
        P.Name AS ProductName,
        PC.Name AS CategoryName,
        SUM(SOD.UnitPrice * SOD.OrderQty) AS Revenue,
        RANK() OVER (PARTITION BY PC.Name ORDER BY SUM(SOD.UnitPrice * SOD.OrderQty) DESC) AS ranknum
    FROM SalesLT.SalesOrderDetail SOD
    JOIN SalesLT.Product P ON SOD.ProductID = P.ProductID
    JOIN SalesLT.ProductCategory PC ON P.ProductCategoryID = PC.ProductCategoryID
    GROUP BY 
        P.ProductID,
        P.Name,
        PC.Name
)
SELECT 
    ProductID,
    ProductName,
    CategoryName,
    Revenue,
    ranknum
FROM ProductRevenue
WHERE ranknum <= 3
ORDER BY CategoryName, ranknum;


