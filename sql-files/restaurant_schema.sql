-- ============================================================
-- RESTAURANT MANAGEMENT SYSTEM - Full Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS RestaurantDB;
USE RestaurantDB;

-- ============================================================
-- 1. CUSTOMERS
-- ============================================================
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Phone VARCHAR(20) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Address TEXT,
    City VARCHAR(50),
    RegistrationDate DATE NOT NULL DEFAULT (CURRENT_DATE),
    IsVIP BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- 2. EMPLOYEES
-- ============================================================
CREATE TABLE Employees (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Position VARCHAR(50) NOT NULL,
    Phone VARCHAR(20) NOT NULL UNIQUE,
    Email VARCHAR(100) UNIQUE,
    Salary DECIMAL(10, 2) NOT NULL CHECK (Salary > 0),
    HireDate DATE NOT NULL,
    Shift VARCHAR(20) DEFAULT 'Morning'
);

-- ============================================================
-- 3. MENU CATEGORIES
-- ============================================================
CREATE TABLE MenuCategories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT
);

-- ============================================================
-- 4. MENU ITEMS
-- ============================================================
CREATE TABLE MenuItems (
    ItemID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryID INT NOT NULL,
    ItemName VARCHAR(100) NOT NULL,
    Description TEXT,
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
    IsAvailable BOOLEAN DEFAULT TRUE,
    PreparationTime INT COMMENT 'Time in minutes',
    FOREIGN KEY (CategoryID) REFERENCES MenuCategories(CategoryID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- 5. RESTAURANT TABLES
-- ============================================================
CREATE TABLE RestaurantTables (
    TableID INT AUTO_INCREMENT PRIMARY KEY,
    TableNumber INT NOT NULL UNIQUE,
    Capacity INT NOT NULL CHECK (Capacity > 0),
    Location VARCHAR(50) DEFAULT 'Main Hall',
    IsActive BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 6. RESERVATIONS
-- ============================================================
CREATE TABLE Reservations (
    ReservationID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    TableID INT NOT NULL,
    EmployeeID INT,
    ReservationDate DATE NOT NULL,
    ReservationTime TIME NOT NULL,
    PartySize INT NOT NULL CHECK (PartySize > 0),
    Status VARCHAR(20) DEFAULT 'Confirmed'
        CHECK (Status IN ('Confirmed', 'Seated', 'Completed', 'Cancelled', 'No-Show')),
    SpecialRequests TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (TableID) REFERENCES RestaurantTables(TableID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ============================================================
-- 7. ORDERS
-- ============================================================
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    EmployeeID INT NOT NULL,
    TableID INT,
    OrderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    OrderType VARCHAR(20) DEFAULT 'Dine-In'
        CHECK (OrderType IN ('Dine-In', 'Takeaway', 'Delivery')),
    Status VARCHAR(20) DEFAULT 'Pending'
        CHECK (Status IN ('Pending', 'Preparing', 'Served', 'Completed', 'Cancelled')),
    TotalAmount DECIMAL(10, 2) DEFAULT 0.00,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (TableID) REFERENCES RestaurantTables(TableID)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ============================================================
-- 8. ORDER DETAILS
-- ============================================================
CREATE TABLE OrderDetails (
    OrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    ItemID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10, 2) NOT NULL CHECK (UnitPrice >= 0),
    Subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (Quantity * UnitPrice) STORED,
    Notes TEXT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (ItemID) REFERENCES MenuItems(ItemID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- 9. PAYMENTS
-- ============================================================
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    PaymentDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Amount DECIMAL(10, 2) NOT NULL CHECK (Amount > 0),
    PaymentMethod VARCHAR(30) NOT NULL
        CHECK (PaymentMethod IN ('Cash', 'Credit Card', 'Debit Card', 'Mobile Wallet', 'Bank Transfer')),
    TransactionReference VARCHAR(100) UNIQUE,
    IsPaid BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_orders_date ON Orders(OrderDate);
CREATE INDEX idx_orders_status ON Orders(Status);
CREATE INDEX idx_reservations_date ON Reservations(ReservationDate);
CREATE INDEX idx_menu_items_category ON MenuItems(CategoryID);
CREATE INDEX idx_payments_order ON Payments(OrderID);

-- ============================================================
-- SAMPLE DATA (20+ records per main table)
-- ============================================================

-- Menu Categories
INSERT INTO MenuCategories (CategoryName, Description) VALUES
('Appetizers', 'Starters and small bites'),
('Soups & Salads', 'Fresh soups and garden salads'),
('Main Course - Chicken', 'Signature chicken dishes'),
('Main Course - Beef', 'Premium beef dishes'),
('Main Course - Seafood', 'Fresh catch of the day'),
('Pasta & Rice', 'Italian pasta and rice dishes'),
('Burgers & Sandwiches', 'Gourmet burgers and sandwiches'),
('Pizza', 'Wood-fired pizzas'),
('Desserts', 'Sweet treats and desserts'),
('Beverages', 'Hot and cold beverages');

-- Menu Items (33)
INSERT INTO MenuItems (CategoryID, ItemName, Description, Price, PreparationTime) VALUES
(1, 'Pol Sambol with Hoppers', 'Crispy bowl-shaped pancake with spicy coconut relish', 850.00, 10),
(1, 'Fish Cutlets', 'Crispy fried spiced fish balls with tartar dip', 1200.00, 12),
(1, 'Chicken Curry Puffs', 'Flaky pastry with spicy chicken filling', 900.00, 15),
(1, 'Vegetable Spring Rolls', 'Crispy rolls with mixed vegetable filling', 750.00, 10),
(1, 'Garlic Prawns', 'Wok-fried garlic chili prawns', 1800.00, 15),
(2, 'Mulligatawny Soup', 'Spiced lentil soup with coconut milk', 850.00, 10),
(2, 'Tomato Soup', 'Creamy tomato soup with croutons', 750.00, 10),
(2, 'Sri Lankan Chicken Salad', 'Spiced chicken strips on fresh garden greens', 1200.00, 8),
(3, 'Sri Lankan Chicken Curry', 'Coconut-based spicy chicken curry', 2200.00, 25),
(3, 'Chicken Biryani', 'Fragrant rice layered with spiced chicken', 2500.00, 30),
(3, 'Devilled Chicken', 'Sweet and spicy stir-fried chicken', 1900.00, 20),
(3, 'Chicken Kottu Roti', 'Chopped roti stir-fried with chicken and vegetables', 1600.00, 18),
(4, 'Beef Curry', 'Slow-cooked Ceylon-style beef curry', 2800.00, 35),
(4, 'Pepper Steak', 'Black pepper beef with onion gravy', 3500.00, 30),
(4, 'Beef Kottu Roti', 'Chopped roti with beef and vegetables', 2200.00, 20),
(5, 'Jumbo Prawn Curry', 'Creamy coconut prawn curry', 3800.00, 30),
(5, 'Fish Ambul Thiyal', 'Traditional sour fish curry with spices', 2500.00, 25),
(5, 'Grilled Ceylon Salmon', 'Fresh salmon with lemon butter sauce', 3500.00, 28),
(6, 'Chicken Fried Rice', 'Wok-fried rice with chicken and vegetables', 1800.00, 18),
(6, 'Seafood Pasta', 'Pasta in garlic butter with mixed seafood', 2500.00, 22),
(6, 'Nasi Goreng', 'Indonesian-style fried rice with egg', 2000.00, 20),
(7, 'Chicken Cheese Burger', 'Grilled chicken patty with cheddar and fries', 1800.00, 15),
(7, 'Fish Burger', 'Crispy fish fillet with tartar sauce and fries', 1600.00, 15),
(8, 'Margherita Pizza', 'Tomato sauce, mozzarella, fresh basil', 2200.00, 18),
(8, 'BBQ Chicken Pizza', 'BBQ sauce, chicken, red onion, cilantro', 2800.00, 20),
(8, 'Seafood Pizza', 'Mixed seafood with mozzarella cheese', 3500.00, 22),
(9, 'Watalappan', 'Steamed coconut custard with jaggery syrup', 650.00, 10),
(9, 'Kiri Bath with Jaggery', 'Milk rice served with palm syrup', 550.00, 8),
(9, 'Tropical Fruit Ice Cream', 'Vanilla ice cream with tropical fruit medley', 800.00, 5),
(9, 'Fresh Fruit Platter', 'Selection of seasonal tropical fruits', 900.00, 5),
(10, 'King Coconut Water', 'Fresh thambili straight from the coconut', 450.00, 3),
(10, 'Fresh Mango Juice', 'Blended ripe mango juice', 550.00, 5),
(10, 'Ceylon Tea', 'Premium Sri Lankan black tea', 350.00, 5),
(10, 'Mineral Water', 'Natural spring mineral water 500ml', 250.00, 2);

-- Customers (24 - Sinhalese, Tamil, Muslim mix)
INSERT INTO Customers (FirstName, LastName, Phone, Email, Address, City) VALUES
('Nimal', 'Perera', '071-2345678', 'nimal.perera@email.com', '10 Galle Road', 'Colombo'),
('Kamala', 'Silva', '077-3456789', 'kamala.silva@email.com', '42 Temple Road', 'Kandy'),
('Priya', 'Jayawardena', '076-4567890', 'priya.j@email.com', '78 Lake Avenue', 'Jaffna'),
('Saman', 'Gunasekara', '075-5678901', 'saman.g@email.com', '23 Hill Street', 'Galle'),
('Ruwan', 'Dissanayake', '071-6789012', 'ruwan.d@email.com', '56 Beach Road', 'Negombo'),
('Shanthi', 'Wickramasinghe', '078-7890123', 'shanthi.w@email.com', '89 River Lane', 'Batticaloa'),
('Thusitha', 'Fernando', '070-8901234', 'thusitha.f@email.com', '34 Sea Street', 'Trincomalee'),
('Anura', 'Weerasinghe', '077-9012345', 'anura.w@email.com', '67 Station Road', 'Anuradhapura'),
('Sepali', 'Rathnayake', '071-0123456', 'sepali.r@email.com', '90 Park Avenue', 'Nuwara Eliya'),
('Dayan', 'Kariyawasam', '076-1234567', 'dayan.k@email.com', '11 Queens Road', 'Colombo'),
('Mahesh', 'Bandara', '075-2345678', 'mahesh.b@email.com', '22 Flower Road', 'Matara'),
('Sriyani', 'Herath', '072-3456789', 'sriyani.h@email.com', '33 Lake Drive', 'Ratnapura'),
('Palitha', 'Senanayake', '078-4567890', 'palitha.s@email.com', '44 Wind Street', 'Kurunegala'),
('Wasantha', 'Kumari', '070-5678901', 'wasantha.k@email.com', '55 Hill Road', 'Badulla'),
('Sivakumar', 'Kandasamy', '072-6789011', 'sivakumar.k@email.com', '66 Market Lane', 'Jaffna'),
('Tharmini', 'Sivapragasam', '075-7890122', 'tharmini.s@email.com', '77 Valley Road', 'Kandy'),
('Kogulakrishnan', 'Tharmalingam', '078-8901233', 'kogula.t@email.com', '88 Harbour Street', 'Galle'),
('Yogeswaran', 'Mahendran', '070-9012344', 'yogeswaran.m@email.com', '99 North Road', 'Batticaloa'),
('Deepa', 'Rajendran', '077-0123455', 'deepa.r@email.com', '111 South Avenue', 'Colombo'),
('Mohamed', 'Ismail', '076-1234566', 'mohamed.i@email.com', '22 Mosque Lane', 'Kandy'),
('Fathima', 'Nusrath', '071-2345677', 'fathima.n@email.com', '44 Bazaar Street', 'Colombo'),
('Ahamed', 'Rizwan', '072-3456788', 'ahamed.r@email.com', '66 Grandpass Road', 'Colombo'),
('Sithy', 'Zareena', '078-4567899', 'sithy.z@email.com', '88 Maradana Road', 'Colombo'),
('Hasan', 'Rafeek', '070-5678900', 'hasan.r@email.com', '12 Muslim Street', 'Kandy');

-- Employees (24 - Sinhalese, Tamil, Muslim mix)
INSERT INTO Employees (FirstName, LastName, Position, Phone, Email, Salary, HireDate, Shift) VALUES
('Ranjith', 'Silva', 'Manager', '077-1111101', 'ranjith.silva@cafulon.lk', 85000.00, '2022-01-15', 'Morning'),
('Rukmani', 'Devi', 'Assistant Manager', '077-1111102', 'rukmani.devi@cafulon.lk', 65000.00, '2022-03-01', 'Evening'),
('Mahinda', 'Senanayake', 'Head Chef', '077-1111103', 'mahinda.s@cafulon.lk', 95000.00, '2021-06-01', 'Morning'),
('Inoka', 'Wimalasena', 'Sous Chef', '077-1111104', 'inoka.w@cafulon.lk', 70000.00, '2022-02-15', 'Evening'),
('Palitha', 'Dharmasena', 'Chef', '077-1111105', 'palitha.d@cafulon.lk', 50000.00, '2023-01-10', 'Morning'),
('Wasantha', 'Perera', 'Chef', '077-1111106', 'wasantha.p@cafulon.lk', 50000.00, '2023-03-05', 'Evening'),
('Sampath', 'Jayasinghe', 'Waiter', '077-1111107', 'sampath.j@cafulon.lk', 28000.00, '2023-06-01', 'Morning'),
('Niroshan', 'Fernando', 'Waiter', '077-1111108', 'niroshan.f@cafulon.lk', 28000.00, '2023-06-01', 'Evening'),
('Saman', 'Weerawansa', 'Waiter', '077-1111109', 'saman.w@cafulon.lk', 28000.00, '2023-07-15', 'Morning'),
('Thusitha', 'Kumara', 'Waiter', '077-1111110', 'thusitha.k@cafulon.lk', 28000.00, '2024-01-10', 'Evening'),
('Nilanthi', 'Gamage', 'Hostess', '077-1111111', 'nilanthi.g@cafulon.lk', 32000.00, '2023-08-01', 'Morning'),
('Gayani', 'Wickramasinghe', 'Hostess', '077-1111112', 'gayani.w@cafulon.lk', 32000.00, '2024-02-01', 'Evening'),
('Aruna', 'Bandara', 'Bartender', '077-1111113', 'aruna.b@cafulon.lk', 40000.00, '2023-09-01', 'Evening'),
('Maheshika', 'Rathnayake', 'Cashier', '077-1111114', 'maheshika.r@cafulon.lk', 32000.00, '2023-10-01', 'Morning'),
('Nuwan', 'Jayawardena', 'Cashier', '077-1111115', 'nuwan.j@cafulon.lk', 32000.00, '2024-01-15', 'Evening'),
('Sumedha', 'Liyanage', 'Kitchen Helper', '077-1111116', 'sumedha.l@cafulon.lk', 22000.00, '2023-11-01', 'Morning'),
('Pradeep', 'Samarasinghe', 'Kitchen Helper', '077-1111117', 'pradeep.s@cafulon.lk', 22000.00, '2024-03-01', 'Evening'),
('Kingsley', 'Gunawardena', 'Security Guard', '077-1111118', 'kingsley.g@cafulon.lk', 25000.00, '2024-04-01', 'Morning'),
('Bandula', 'Wijesinghe', 'Security Guard', '077-1111119', 'bandula.w@cafulon.lk', 25000.00, '2024-04-01', 'Evening'),
('Chandra', 'Kumari', 'Cleaner', '077-1111120', 'chandra.k@cafulon.lk', 20000.00, '2024-05-01', 'Morning'),
('Rajeshwar', 'Thiyagarajah', 'Chef', '077-1111121', 'rajeshwar.t@cafulon.lk', 55000.00, '2023-04-01', 'Morning'),
('Fathima', 'Rizki', 'Cashier', '077-1111122', 'fathima.r@cafulon.lk', 35000.00, '2024-06-01', 'Evening'),
('Mohamed', 'Haniffa', 'Waiter', '077-1111123', 'mohamed.h@cafulon.lk', 30000.00, '2024-06-15', 'Morning'),
('Nithya', 'Balasubramaniam', 'Hostess', '077-1111124', 'nithya.b@cafulon.lk', 35000.00, '2024-07-01', 'Evening');

-- Restaurant Tables
INSERT INTO RestaurantTables (TableNumber, Capacity, Location) VALUES
(1, 2, 'Window Side'),
(2, 2, 'Window Side'),
(3, 4, 'Main Hall'),
(4, 4, 'Main Hall'),
(5, 6, 'Main Hall'),
(6, 6, 'Main Hall'),
(7, 8, 'Private Corner'),
(8, 8, 'Private Corner'),
(9, 4, 'Balcony'),
(10, 4, 'Balcony'),
(11, 2, 'Bar Area'),
(12, 2, 'Bar Area'),
(13, 10, 'VIP Room'),
(14, 4, 'Garden'),
(15, 4, 'Garden');

-- Reservations (24)
INSERT INTO Reservations (CustomerID, TableID, EmployeeID, ReservationDate, ReservationTime, PartySize, Status, SpecialRequests) VALUES
(1, 3, 1, '2026-06-01', '19:00:00', 4, 'Completed', NULL),
(2, 5, 7, '2026-06-01', '20:00:00', 5, 'Completed', 'Birthday celebration'),
(3, 1, 7, '2026-06-02', '18:30:00', 2, 'Completed', NULL),
(4, 7, 11, '2026-06-02', '20:00:00', 7, 'Completed', 'Anniversary dinner'),
(5, 2, 7, '2026-06-03', '19:00:00', 2, 'Completed', NULL),
(6, 4, 9, '2026-06-03', '19:30:00', 4, 'Completed', 'Vegetarian options needed'),
(7, 13, 1, '2026-06-04', '20:00:00', 10, 'Completed', 'Corporate dinner'),
(8, 9, 11, '2026-06-04', '18:00:00', 4, 'Completed', NULL),
(9, 6, 9, '2026-06-05', '19:00:00', 6, 'Completed', NULL),
(10, 15, 7, '2026-06-05', '20:00:00', 4, 'Completed', 'Allergy: nuts'),
(11, 3, 1, '2026-06-06', '19:30:00', 4, 'Completed', NULL),
(12, 8, 11, '2026-06-06', '20:30:00', 8, 'Completed', 'Birthday cake requested'),
(13, 10, 9, '2026-06-07', '18:00:00', 3, 'Completed', NULL),
(14, 1, 7, '2026-06-07', '19:00:00', 2, 'Completed', NULL),
(15, 14, 7, '2026-06-08', '19:30:00', 4, 'Completed', NULL),
(16, 4, 9, '2026-06-08', '20:00:00', 4, 'Completed', NULL),
(1, 5, 7, '2026-06-09', '19:00:00', 5, 'Seated', 'Window seat preferred'),
(2, 7, 11, '2026-06-09', '20:30:00', 6, 'Seated', NULL),
(3, 9, 11, '2026-06-10', '18:30:00', 3, 'Confirmed', NULL),
(4, 2, 7, '2026-06-10', '19:00:00', 2, 'Confirmed', 'Honeymoon dinner'),
(5, 13, 1, '2026-06-11', '19:00:00', 8, 'Confirmed', 'Business meeting'),
(6, 6, 9, '2026-06-11', '20:00:00', 6, 'Confirmed', NULL),
(7, 15, 7, '2026-06-12', '19:30:00', 4, 'Confirmed', NULL),
(20, 3, 7, '2026-06-12', '18:00:00', 3, 'Cancelled', 'Customer called to cancel');

-- Orders (24)
INSERT INTO Orders (CustomerID, EmployeeID, TableID, OrderDate, OrderType, Status, TotalAmount) VALUES
(1, 7, 3, '2026-06-01 19:15:00', 'Dine-In', 'Completed', 4350.00),
(2, 8, 5, '2026-06-01 20:10:00', 'Dine-In', 'Completed', 8800.00),
(3, 7, 1, '2026-06-02 18:45:00', 'Dine-In', 'Completed', 3350.00),
(4, 10, 7, '2026-06-02 20:15:00', 'Dine-In', 'Completed', 8750.00),
(5, 9, 2, '2026-06-03 19:10:00', 'Dine-In', 'Completed', 6850.00),
(6, 9, 4, '2026-06-03 19:45:00', 'Dine-In', 'Completed', 7750.00),
(7, 7, 13, '2026-06-04 20:10:00', 'Dine-In', 'Completed', 25100.00),
(8, 8, 9, '2026-06-04 18:15:00', 'Dine-In', 'Completed', 2750.00),
(9, 9, 6, '2026-06-05 19:20:00', 'Dine-In', 'Completed', 10700.00),
(10, 7, 15, '2026-06-05 20:10:00', 'Dine-In', 'Completed', 6100.00),
(11, 10, 3, '2026-06-06 19:40:00', 'Dine-In', 'Completed', 5200.00),
(12, 8, 8, '2026-06-06 20:45:00', 'Dine-In', 'Completed', 9800.00),
(13, 9, 10, '2026-06-07 18:15:00', 'Dine-In', 'Completed', 8950.00),
(14, 7, 1, '2026-06-07 19:10:00', 'Dine-In', 'Completed', 4750.00),
(15, 9, 14, '2026-06-08 19:45:00', 'Dine-In', 'Completed', 5800.00),
(16, 10, 4, '2026-06-08 20:15:00', 'Dine-In', 'Completed', 4550.00),
(NULL, 7, NULL, '2026-06-09 12:30:00', 'Takeaway', 'Completed', 4050.00),
(NULL, 8, NULL, '2026-06-09 13:15:00', 'Delivery', 'Completed', 2550.00),
(1, 9, 5, '2026-06-09 19:20:00', 'Dine-In', 'Completed', 6300.00),
(2, 10, 7, '2026-06-09 20:45:00', 'Dine-In', 'Completed', 7300.00),
(3, 7, 9, '2026-06-10 18:45:00', 'Dine-In', 'Preparing', 3850.00),
(4, 8, 2, '2026-06-10 19:15:00', 'Dine-In', 'Preparing', 5200.00),
(NULL, 9, NULL, '2026-06-10 12:00:00', 'Takeaway', 'Pending', 0.00),
(NULL, 10, NULL, '2026-06-10 12:30:00', 'Delivery', 'Pending', 0.00);

-- Order Details (21 orders with items)
INSERT INTO OrderDetails (OrderID, ItemID, Quantity, UnitPrice) VALUES
(1, 1, 2, 850.00),
(1, 9, 1, 2200.00),
(1, 30, 1, 450.00),
(2, 4, 2, 750.00),
(2, 14, 1, 2200.00),
(2, 13, 1, 3500.00),
(2, 29, 1, 900.00),
(2, 32, 2, 550.00),
(3, 6, 1, 850.00),
(3, 10, 1, 2500.00),
(4, 7, 2, 750.00),
(4, 11, 1, 1900.00),
(4, 15, 1, 3800.00),
(4, 26, 1, 650.00),
(4, 30, 2, 450.00),
(5, 2, 1, 1200.00),
(5, 17, 1, 3500.00),
(5, 22, 1, 1600.00),
(5, 31, 1, 550.00),
(6, 5, 2, 1800.00),
(6, 18, 1, 1800.00),
(6, 20, 1, 2000.00),
(6, 33, 1, 350.00),
(7, 3, 5, 900.00),
(7, 13, 4, 3500.00),
(7, 23, 2, 2200.00),
(7, 31, 4, 550.00),
(8, 1, 1, 850.00),
(8, 6, 1, 850.00),
(8, 27, 1, 550.00),
(8, 34, 2, 250.00),
(9, 9, 2, 2200.00),
(9, 11, 1, 1900.00),
(9, 18, 2, 1800.00),
(9, 28, 1, 800.00),
(10, 10, 1, 2500.00),
(10, 16, 1, 2500.00),
(10, 26, 1, 650.00),
(10, 30, 1, 450.00),
(11, 6, 1, 850.00),
(11, 14, 1, 2200.00),
(11, 21, 1, 1800.00),
(11, 32, 1, 350.00),
(12, 2, 2, 1200.00),
(12, 12, 2, 2800.00),
(12, 29, 1, 900.00),
(12, 30, 2, 450.00),
(13, 5, 2, 1800.00),
(13, 20, 1, 2000.00),
(13, 24, 1, 2800.00),
(13, 31, 1, 550.00),
(14, 7, 1, 750.00),
(14, 17, 1, 3500.00),
(14, 34, 2, 250.00),
(15, 1, 1, 850.00),
(15, 15, 1, 3800.00),
(15, 30, 1, 450.00),
(15, 32, 2, 550.00),
(16, 4, 2, 750.00),
(16, 16, 1, 2500.00),
(16, 31, 1, 550.00),
(17, 13, 1, 3500.00),
(17, 31, 1, 550.00),
(18, 23, 1, 2200.00),
(18, 33, 1, 350.00),
(19, 10, 1, 2500.00),
(19, 18, 1, 1800.00),
(19, 20, 1, 2000.00),
(20, 12, 1, 2800.00),
(20, 15, 1, 3800.00),
(20, 32, 2, 350.00),
(21, 1, 1, 850.00),
(21, 11, 1, 1900.00),
(21, 31, 2, 550.00);

-- Payments (20)
INSERT INTO Payments (OrderID, Amount, PaymentMethod, TransactionReference, IsPaid) VALUES
(1, 4350.00, 'Credit Card', 'TXN-20260601-001', TRUE),
(2, 8800.00, 'Cash', 'TXN-20260601-002', TRUE),
(3, 3350.00, 'Debit Card', 'TXN-20260602-001', TRUE),
(4, 8750.00, 'Credit Card', 'TXN-20260602-002', TRUE),
(5, 6850.00, 'Cash', 'TXN-20260603-001', TRUE),
(6, 7750.00, 'Mobile Wallet', 'TXN-20260603-002', TRUE),
(7, 25100.00, 'Credit Card', 'TXN-20260604-001', TRUE),
(8, 2750.00, 'Cash', 'TXN-20260604-002', TRUE),
(9, 10700.00, 'Credit Card', 'TXN-20260605-001', TRUE),
(10, 6100.00, 'Debit Card', 'TXN-20260605-002', TRUE),
(11, 5200.00, 'Cash', 'TXN-20260606-001', TRUE),
(12, 9800.00, 'Credit Card', 'TXN-20260606-002', TRUE),
(13, 8950.00, 'Mobile Wallet', 'TXN-20260607-001', TRUE),
(14, 4750.00, 'Cash', 'TXN-20260607-002', TRUE),
(15, 5800.00, 'Credit Card', 'TXN-20260608-001', TRUE),
(16, 4550.00, 'Debit Card', 'TXN-20260608-002', TRUE),
(17, 4050.00, 'Cash', 'TXN-20260609-001', TRUE),
(18, 2550.00, 'Mobile Wallet', 'TXN-20260609-002', TRUE),
(19, 6300.00, 'Credit Card', 'TXN-20260609-003', TRUE),
(20, 7300.00, 'Cash', 'TXN-20260609-004', TRUE);

-- ============================================================
-- USEFUL VIEWS
-- ============================================================

-- View: Active Menu Items
CREATE VIEW ActiveMenu AS
SELECT mi.ItemID, mi.ItemName, mc.CategoryName, mi.Price, mi.PreparationTime
FROM MenuItems mi
JOIN MenuCategories mc ON mi.CategoryID = mc.CategoryID
WHERE mi.IsAvailable = TRUE
ORDER BY mc.CategoryName, mi.ItemName;

-- View: Today's Reservations
CREATE VIEW TodaysReservations AS
SELECT r.ReservationID, c.FirstName, c.LastName, c.Phone,
       t.TableNumber, r.ReservationTime, r.PartySize, r.Status
FROM Reservations r
JOIN Customers c ON r.CustomerID = c.CustomerID
JOIN RestaurantTables t ON r.TableID = t.TableID
WHERE r.ReservationDate = CURRENT_DATE
ORDER BY r.ReservationTime;

-- View: Order Summary
CREATE VIEW OrderSummary AS
SELECT o.OrderID, o.OrderDate, o.OrderType, o.Status,
       CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
       CONCAT(e.FirstName, ' ', e.LastName) AS ServedBy,
       o.TotalAmount
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID;

-- View: Daily Sales Report
CREATE VIEW DailySales AS
SELECT DATE(o.OrderDate) AS SaleDate,
       COUNT(DISTINCT o.OrderID) AS TotalOrders,
       SUM(o.TotalAmount) AS TotalRevenue,
       AVG(o.TotalAmount) AS AvgOrderValue
FROM Orders o
WHERE o.Status = 'Completed'
GROUP BY DATE(o.OrderDate);

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- Calculate order total
DELIMITER //
CREATE PROCEDURE CalculateOrderTotal(IN orderID INT)
BEGIN
    UPDATE Orders o
    SET o.TotalAmount = (
        SELECT COALESCE(SUM(Subtotal), 0)
        FROM OrderDetails
        WHERE OrderID = orderID
    )
    WHERE o.OrderID = orderID;
END //
DELIMITER ;
