-- Project Scenario

-- Mint Classics Company, a retailer of classic model cars and other vehicles, is looking at closing one of their storage facilities. 
-- To support a data-based business decision, they are looking for suggestions and recommendations for reorganizing or reducing inventory, while still maintaining timely service to their customers. 
-- As a data analyst, you have been asked to use MySQL Workbench to familiarize yourself with the general business by examining the current data. You will be provided with a data model and sample data tables to review. 
-- You will then need to isolate and identify those parts of the data that could be useful in deciding how to reduce inventory. You will write queries to answer questions like these:

-- 1) Where are items stored and if they were rearranged, could a warehouse be eliminated?

-- 2) How are inventory numbers related to sales figures? Do the inventory counts seem appropriate for each item?

-- 3) Are we storing items that are not moving? Are any items candidates for being dropped from the product line?

-- The answers to questions like those should help you to formulate suggestions and recommendations for reducing inventory with the goal of closing one of the storage facilities. 


-- Identify the total number of warehouses and their capacity.

SELECT 
    warehouseCode, 
    warehouseName, 
    warehousePctCap 
FROM 
    mintclassics.warehouses
ORDER BY 
    warehouseCode;

-- There are four warehouses, each with its unique code, name, and current capacity in percent. 
-- Among them, Warehouse C stands out with ample space, currently filled at only 50%.


-- Identify the total of products offered by this company.

SELECT 
    COUNT(DISTINCT productName) AS unique_product_count
FROM 
    mintclassics.products;

-- The company currently holds a diverse inventory of 110 distinct products.


-- Determine if any products are stored in multiple warehouses.

SELECT 
    p.productName, 
    COUNT(DISTINCT w.warehouseCode) AS warehouse_count
FROM 
    mintclassics.products p
JOIN 
    mintclassics.warehouses w 
ON 
    p.warehouseCode = w.warehouseCode
GROUP BY 
    p.productName
HAVING 
    COUNT(w.warehouseCode) > 1;

-- No products are stored across multiple warehouses. 
-- Thus, it's evident that each warehouse exclusively stores specific product lines.


-- Identify the unique product count and total stock in each warehouse.

SELECT 
    w.warehouseCode, 
    w.warehouseName, 
    COUNT(DISTINCT p.productName) AS unique_product_count,
    SUM(p.quantityInStock) AS total_stock
FROM 
    mintclassics.warehouses w
JOIN 
    mintclassics.products p
ON 
    w.warehouseCode = p.warehouseCode
GROUP BY 
    w.warehouseCode, 
    w.warehouseName;

-- Warehouse B boasts an impressive inventory, housing a total of 38 different products with a combined stock of 219.183 units, making it the warehouse with the highest storage capacity.


-- Identify which product lines are stored in each warehouse.

SELECT 
    w.warehouseCode, 
    w.warehouseName, 
    p.productLine, 
    COUNT(p.productCode) AS total_product
FROM 
    mintclassics.warehouses w
JOIN 
    mintclassics.products p
ON 
    w.warehouseCode = p.warehouseCode
GROUP BY 
    w.warehouseCode, 
    w.warehouseName, 
    p.productLine;

--   Warehouse A (North): Planes + Motorcycles
--   Warehouse B (East): Classic Cars
--   Warehouse C (West): Vintage Cars
--   Warehouse D (South): Trucks + Buses, Ships, Trains


-- Determine the product lines with the highest and lowest number of sales.

SELECT 
    p.productLine, 
    SUM(o.priceEach * o.quantityOrdered) AS sales
FROM 
    mintclassics.products p
JOIN 
    mintclassics.orderdetails o
ON 
    p.productCode = o.productCode
GROUP BY 
    p.productLine
ORDER BY 
    sales;


-- Investigating Business Issues and Identifying Affected Tables

-- I will investigate Mint Classics' business challenge, which involves the company’s plan to close one of its warehouses. 
-- My approach will include identifying the relevant tables and utilizing SQL queries to extract the necessary information. 
-- To aid in the analysis, I will create a temporary table that compares product stock levels with inventory remaining after fulfilling shipped and resolved orders. 
-- This table will serve as a valuable tool for pinpointing overstocked items, adequately stocked products, and potential understock scenarios.

SELECT
    w.warehouseCode, 
    p.productCode, 
    p.productName, 
    p.quantityInStock, 
    COALESCE(SUM(oi.quantityOrdered), 0) AS total_ordered,
    (p.quantityInStock - COALESCE(SUM(oi.quantityOrdered), 0)) AS remaining_stock,
    CASE 
        WHEN (p.quantityInStock - COALESCE(SUM(oi.quantityOrdered), 0)) > 0 THEN 'Overstocked'
        WHEN (p.quantityInStock - COALESCE(SUM(oi.quantityOrdered), 0)) < 0 THEN 'Understocked'
        ELSE 'Appropriately Stocked'
    END AS stock_status
FROM 
    mintclassics.warehouses w
JOIN
    mintclassics.products p
ON 
    w.warehouseCode = p.warehouseCode
LEFT JOIN
    mintclassics.orderdetails oi
ON
    p.productCode = oi.productCode
GROUP BY
    w.warehouseCode, 
    p.productCode, 
    p.productName, 
    p.quantityInStock
ORDER BY
    w.warehouseCode, 
    p.productCode;


-- Then, determine the quantity of products that are wellstocked, overstocked and understocked in each warehouse.   

SELECT 
    warehouseCode, 
    COUNT(*) AS overstocked_product_count
FROM (
    SELECT 
        w.warehouseCode, 
        p.quantityInStock - COALESCE(SUM(oi.quantityOrdered), 0) AS remaining_stock
    FROM 
        mintclassics.warehouses w
    JOIN 
        mintclassics.products p
    ON 
        w.warehouseCode = p.warehouseCode
    LEFT JOIN 
        mintclassics.orderdetails oi
    ON 
        p.productCode = oi.productCode
    GROUP BY 
        w.warehouseCode, 
        p.productCode, 
        p.quantityInStock
) subquery
WHERE 
    remaining_stock > 0
GROUP BY 
    warehouseCode;

-- It appears that Warehouse B has the highest quantity of overstocked products, totaling 37 items, while both Warehouse A and Warehouse C have the same number of overstocked products, amounting to 21 each.

-- Upon review, it is clear that Warehouse B stores Classic cars, which have the lowest sales performance and the highest number of overstocked products. 
-- Despite these challenges, Warehouse B holds a remarkable inventory of 38 unique products with a total stock of 219,183 units, making it the facility with the greatest storage capacity in our network.

-- In contrast, Warehouse C has the smallest storage capacity among the four facilities. 
-- Currently, it is operating at just 50% capacity, leaving a significant portion of its space underutilized, which represents an inefficient use of resources.

-- Given these observations, it is recommended to close Warehouse C and transfer its inventory to Warehouse B. 
-- This consolidation will not only optimize the use of Warehouse B's expansive storage space but also improve inventory management by centralizing related product lines in a single location.


-- Further More

SELECT 
    p.productCode,
    p.productName,
    p.productLine,
    SUM(oi.priceEach * oi.quantityOrdered) AS sales
FROM
    mintclassics.orderdetails oi
RIGHT JOIN 
    mintclassics.products p
ON 
    p.productCode = oi.productCode
GROUP BY 
    p.productCode, 
    p.productName, 
    p.productLine;

-- Products that have never been sold or show consistently low sales should be considered for reduction. 
-- These slow-moving items occupy valuable storage space, incur unnecessary costs, and detract focus from high-demand products. 
-- Removing such products will optimize inventory, reduce overhead expenses, and improve overall profitability by focusing on bestsellers.