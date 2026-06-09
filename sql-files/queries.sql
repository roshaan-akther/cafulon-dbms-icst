-- ============================================================
-- RESTAURANT MANAGEMENT SYSTEM - 10 SQL Queries
-- ============================================================
-- Covers: SELECT, INSERT, UPDATE, DELETE,
--         INNER JOIN, LEFT JOIN, GROUP BY, ORDER BY,
--         Aggregate Functions
-- ============================================================

USE RestaurantDB;

-- -------------------------------------------------------
-- Q1: SELECT - List all available menu items with prices
-- -------------------------------------------------------
SELECT ItemName AS 'Dish', Price AS 'Price (LKR)', PreparationTime AS 'Prep (min)'
FROM MenuItems
WHERE IsAvailable = TRUE
ORDER BY Price ASC;

-- -------------------------------------------------------
-- Q2: INSERT - Add a new customer
-- -------------------------------------------------------
INSERT INTO Customers (FirstName, LastName, Phone, Email, Address, City)
VALUES ('Supun', 'Weerasinghe', '071-8889990', 'supun.w@email.com', '77 Kandy Road', 'Colombo');

-- -------------------------------------------------------
-- Q3: UPDATE - Update menu item price
-- -------------------------------------------------------
UPDATE MenuItems
SET Price = 2800.00
WHERE ItemName = 'Chicken Biryani';

-- -------------------------------------------------------
-- Q4: DELETE - Remove a cancelled reservation
-- -------------------------------------------------------
DELETE FROM Reservations
WHERE ReservationID = 24 AND Status = 'Cancelled';

-- -------------------------------------------------------
-- Q5: INNER JOIN - Show order details with customer & item names
-- -------------------------------------------------------
SELECT o.OrderID, CONCAT(c.FirstName, ' ', c.LastName) AS Customer,
       mi.ItemName, od.Quantity, od.Subtotal
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN MenuItems mi ON od.ItemID = mi.ItemID
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderID;

-- -------------------------------------------------------
-- Q6: LEFT JOIN - Show all customers and their orders (including customers with no orders)
-- -------------------------------------------------------
SELECT CONCAT(c.FirstName, ' ', c.LastName) AS Customer,
       c.Phone, COUNT(o.OrderID) AS TotalOrders,
       COALESCE(SUM(o.TotalAmount), 0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalSpent DESC;

-- -------------------------------------------------------
-- Q7: GROUP BY with Aggregate - Daily sales report
-- -------------------------------------------------------
SELECT DATE(o.OrderDate) AS SaleDate,
       COUNT(*) AS NumberOfOrders,
       SUM(o.TotalAmount) AS Revenue,
       ROUND(AVG(o.TotalAmount), 2) AS AvgOrderValue,
       MAX(o.TotalAmount) AS LargestOrder
FROM Orders o
WHERE o.Status = 'Completed'
GROUP BY DATE(o.OrderDate)
ORDER BY SaleDate DESC;

-- -------------------------------------------------------
-- Q8: Aggregate - Top selling menu items
-- -------------------------------------------------------
SELECT mi.ItemName, mc.CategoryName,
       SUM(od.Quantity) AS TotalSold,
       SUM(od.Subtotal) AS TotalRevenue
FROM OrderDetails od
JOIN MenuItems mi ON od.ItemID = mi.ItemID
JOIN MenuCategories mc ON mi.CategoryID = mc.CategoryID
GROUP BY mi.ItemID
ORDER BY TotalSold DESC
LIMIT 10;

-- -------------------------------------------------------
-- Q9: Aggregate - Employee performance (total sales served)
-- -------------------------------------------------------
SELECT CONCAT(e.FirstName, ' ', e.LastName) AS Employee,
       e.Position, COUNT(o.OrderID) AS OrdersServed,
       SUM(o.TotalAmount) AS TotalSales
FROM Employees e
LEFT JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY e.EmployeeID
ORDER BY TotalSales DESC;

-- -------------------------------------------------------
-- Q10: Multi-Join - Full reservation details with customer, table, and employee
-- -------------------------------------------------------
SELECT r.ReservationID,
       CONCAT(c.FirstName, ' ', c.LastName) AS Customer,
       r.ReservationDate, r.ReservationTime, r.PartySize,
       t.TableNumber, t.Location,
       CONCAT(e.FirstName, ' ', e.LastName) AS HandledBy,
       r.Status
FROM Reservations r
JOIN Customers c ON r.CustomerID = c.CustomerID
JOIN RestaurantTables t ON r.TableID = t.TableID
LEFT JOIN Employees e ON r.EmployeeID = e.EmployeeID
ORDER BY r.ReservationDate DESC, r.ReservationTime DESC;
