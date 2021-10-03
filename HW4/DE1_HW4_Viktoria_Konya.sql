
-- Select db
USE classicmodels;

-- HW 4
-- INNER join orders,orderdetails,products and customers. Return back: orderNumber, priceEach, quantityOrdered, productName, productLine, city, country, orderDate
SELECT 
	o.orderNumber
    ,od.priceEach
    ,od.quantityOrdered
    ,p.productName
    ,p.productLine
    ,c.city
    ,c.country
    ,o.orderDate

FROM orders o

INNER JOIN orderdetails od
	ON o.orderNumber = od.orderNumber

INNER JOIN products p
	ON od.productCode = p.productCode
    
INNER JOIN customers c
	ON o.customerNumber = c.customerNumber;