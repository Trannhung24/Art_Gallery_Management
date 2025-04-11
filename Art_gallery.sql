CREATE DATABASE ART_GALLERY_MANAGER
-- Bảng nghệ sĩ
CREATE TABLE Artists (
    ArtistID INT PRIMARY KEY,
    FullName VARCHAR(100),
    Achievements TEXT
);

-- Bảng tác phẩm nghệ thuật
CREATE TABLE Artworks (
    ArtID INT PRIMARY KEY,
    Title VARCHAR(100),
    ArtistID INT,
    ArtType VARCHAR(50),
    Medium VARCHAR(50),
    ProductDetails TEXT,
    FOREIGN KEY (ArtistID) REFERENCES Artists(ArtistID)
);

-- Bảng sự kiện trưng bày
CREATE TABLE Exhibitions (
    ExhibitionID INT PRIMARY KEY,
    Venue VARCHAR(100),
    Date DATE,
    Location VARCHAR(100)
);

-- Bảng người dùng
CREATE TABLE Users (
    UserID INT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100)
);

-- Bảng giao dịch mua hàng
CREATE TABLE GallerySales (
    SaleID INT PRIMARY KEY,
    ArtID INT,
    UserID INT,
    Price DECIMAL(12, 2),
    SaleDate DATE,
    FOREIGN KEY (ArtID) REFERENCES Artworks(ArtID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
INSERT INTO Artists (ArtistID, FullName, Achievements)
VALUES
(1, 'Leonardo da Vinci', 'Mona Lisa, The Last Supper'),
(2, 'Vincent van Gogh', 'Starry Night, Sunflowers'),
(3, 'Pablo Picasso', 'Guernica, Les Demoiselles d\Avignon');
INSERT INTO Artworks (ArtID, Title, ArtistID, ArtType, Medium, ProductDetails)
VALUES
(101, 'Mona Lisa', 1, 'Portrait', 'Oil on poplar', 'Painted in the 16th century, currently in the Louvre'),
(102, 'Starry Night', 2, 'Landscape', 'Oil on canvas', 'One of Van Gogh\s most famous works'),
(103, 'Guernica', 3, 'Mural', 'Oil on canvas', 'Anti-war painting created in 1937'),
(104, 'The Last Supper', 1, 'Religious', 'Tempera and oil', 'Depicts Jesus and his disciples'),
(105, 'Sunflowers', 2, 'Still Life', 'Oil on canvas', 'A series of paintings by Van Gogh');
INSERT INTO Exhibitions (ExhibitionID, Venue, Date, Location)
VALUES
(201, 'Louvre Museum', '2023-05-10', 'Paris'),
(202, 'MoMA', '2023-07-15', 'New York'),
(203, 'Museo Reina Sofia', '2023-09-01', 'Madrid');
INSERT INTO Users (UserID, Name, Email)
VALUES
(301, 'Alice Nguyen', 'alice.nguyen@example.com'),
(302, 'Bob Tran', 'bob.tran@example.com'),
(303, 'Charlie Le', 'charlie.le@example.com');
INSERT INTO GallerySales (SaleID, ArtID, UserID, Price, SaleDate)
VALUES
(401, 101, 301, 1500000.00, '2023-06-01'),
(402, 102, 302, 850000.00, '2023-06-10'),
(403, 105, 303, 920000.00, '2023-06-20'),
(404, 103, 301, 1300000.00, '2023-07-01');
-- 1. Truy vấn liệt kê tất cả tác phẩm nghệ thuật cùng nghệ sĩ và tổng số tác phẩm của họ
SELECT 
    a.FullName AS ArtistName,                                 -- Tên nghệ sĩ
    aw.Title AS ArtworkTitle,                                 -- Tên tác phẩm
    COUNT(*) OVER (PARTITION BY a.ArtistID) AS TotalWorks     -- Tổng số tác phẩm của nghệ sĩ đó
FROM Artists a
JOIN Artworks aw ON a.ArtistID = aw.ArtistID;
-- 2. Danh sách các tranh đã bán kèm người mua và thứ hạng theo giá bán (giá cao nhất xếp hạng 1)
SELECT 
    aw.Title AS ArtworkTitle,                     -- Tên tranh
    u.Name AS BuyerName,                          -- Tên người mua
    gs.Price,                                     -- Giá bán
    RANK() OVER (ORDER BY gs.Price DESC) AS RankByPrice  -- Xếp hạng theo giá bán (cao -> thấp)
FROM GallerySales gs
JOIN Artworks aw ON gs.ArtID = aw.ArtID
JOIN Users u ON gs.UserID = u.UserID;
--3. CTE: Tính tổng doanh thu từ việc bán tranh của từng nghệ sĩ
WITH ArtistRevenue AS (
    SELECT 
        a.ArtistID,                       -- ID nghệ sĩ
        a.FullName,                       -- Tên nghệ sĩ
        SUM(gs.Price) AS TotalRevenue    -- Tổng doanh thu
    FROM GallerySales gs
    JOIN Artworks aw ON gs.ArtID = aw.ArtID
    JOIN Artists a ON aw.ArtistID = a.ArtistID
    GROUP BY a.ArtistID, a.FullName
)
-- Truy vấn chính: lấy doanh thu theo nghệ sĩ, sắp xếp giảm dần
SELECT * 
FROM ArtistRevenue
ORDER BY TotalRevenue DESC;
-- 4. Truy vấn xác định tranh có giá bán cao nhất của từng nghệ sĩ (ROW_NUMBER dùng để chọn hàng đầu tiên)
WITH RankedSales AS (
    SELECT 
        a.FullName AS ArtistName,                -- Tên nghệ sĩ
        aw.Title AS ArtworkTitle,                -- Tên tác phẩm
        gs.Price,                                -- Giá bán
        ROW_NUMBER() OVER (
            PARTITION BY a.ArtistID 
            ORDER BY gs.Price DESC
        ) AS rn                                  -- Đánh số thứ tự, 1 là giá cao nhất
    FROM GallerySales gs
    JOIN Artworks aw ON gs.ArtID = aw.ArtID
    JOIN Artists a ON aw.ArtistID = a.ArtistID
)
-- Lọc ra mỗi nghệ sĩ chỉ lấy 1 tranh giá cao nhất
SELECT 
    ArtistName,
    ArtworkTitle,
    Price
FROM RankedSales
WHERE rn = 1;
-- 5. Truy vấn thống kê theo loại tranh:
-- - Đếm số lượng tranh thuộc từng loại
-- - Tính tổng doanh thu từ việc bán các tranh đó
SELECT 
    aw.ArtType,                                 -- Loại tranh (Portrait, Landscape,...)
    COUNT(aw.ArtID) AS TotalArtworks,           -- Tổng số tác phẩm thuộc loại này
    SUM(gs.Price) AS TotalRevenue               -- Tổng doanh thu từ loại tranh này
FROM Artworks aw
LEFT JOIN GallerySales gs ON aw.ArtID = gs.ArtID
GROUP BY aw.ArtType
ORDER BY TotalRevenue DESC;                     -- Sắp xếp theo doanh thu giảm dần
-- 6. Truy vấn tìm người dùng mua nhiều tranh nhất:
-- - Đếm số lần mua
-- - Tính tổng tiền đã chi
SELECT TOP 1
    u.Name AS BuyerName,                        -- Tên người mua
    COUNT(gs.SaleID) AS TotalPurchases,         -- Số lần mua
    SUM(gs.Price) AS TotalSpent                 -- Tổng tiền đã chi
FROM GallerySales gs
JOIN Users u ON gs.UserID = u.UserID
GROUP BY u.Name
ORDER BY TotalPurchases DESC;                   -- Chọn người mua nhiều nhất
-- 7. Truy vấn tìm các tác phẩm chưa từng được bán:
-- - Dùng LEFT JOIN để tìm các tranh không có bản ghi trong GallerySales
SELECT 
    aw.Title AS UnsoldArtwork,                  -- Tên tác phẩm chưa bán
    a.FullName AS Artist                        -- Tên nghệ sĩ tạo ra
FROM Artworks aw
JOIN Artists a ON aw.ArtistID = a.ArtistID
LEFT JOIN GallerySales gs ON aw.ArtID = gs.ArtID
WHERE gs.SaleID IS NULL;                        -- Chỉ lấy những tranh chưa có bản ghi bán
-- 8. Truy vấn kết hợp Users với tổng số tiền họ đã chi (nếu có)
-- Dùng CASE để phân loại khách hàng
SELECT 
    u.UserID,
    u.Name,
    u.Email,
    ISNULL(SUM(gs.Price), 0) AS TotalSpent,     -- Tổng tiền đã chi (0 nếu chưa mua)
    CASE 
        WHEN SUM(gs.Price) IS NULL THEN 'Chưa mua'    -- Chưa từng mua tranh
        WHEN SUM(gs.Price) >= 1000000 THEN 'Khách VIP'-- Chi nhiều => VIP
        ELSE 'Khách thường'                           -- Các trường hợp còn lại
    END AS CustomerType
FROM Users u
LEFT JOIN GallerySales gs ON u.UserID = gs.UserID
GROUP BY u.UserID, u.Name, u.Email;
-- 9. Truy vấn tìm các tranh đã bán trong vòng 30 ngày tính từ hôm nay
-- DATEDIFF để tính số ngày giữa ngày bán và ngày hiện tại
SELECT 
    aw.Title,
    gs.SaleDate,
    gs.Price,
    DATEDIFF(DAY, gs.SaleDate, GETDATE()) AS DaysAgo -- Số ngày trước đây tranh được bán
FROM GallerySales gs
JOIN Artworks aw ON gs.ArtID = aw.ArtID
WHERE DATEDIFF(DAY, gs.SaleDate, GETDATE()) <= 30;   -- Chỉ lấy các tranh bán trong 30 ngày gần đây
-- 10. Truy vấn doanh thu bán tranh theo tháng:
-- - Dùng hàm YEAR() và MONTH() để tách theo thời gian
-- - GROUP BY theo năm và tháng
SELECT 
    YEAR(SaleDate) AS SaleYear,                -- Năm bán
    MONTH(SaleDate) AS SaleMonth,              -- Tháng bán
    SUM(Price) AS MonthlyRevenue               -- Tổng doanh thu trong tháng đó
FROM GallerySales
GROUP BY YEAR(SaleDate), MONTH(SaleDate)
ORDER BY SaleYear, SaleMonth;
