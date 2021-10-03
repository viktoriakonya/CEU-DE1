
-- Select database
USE birdstrikes;

-- Exercise 1 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- Based on the previous chapter, create a table called “employee” with two columns: “id” and “employee_name”. NULL values should not be accepted for these 2 columns.
DROP TABLE IF EXISTS employee;

CREATE TABLE employee 
(id INTEGER NOT NULL,
employee_name VARCHAR(50) NOT NULL,
PRIMARY KEY(id));

-- Exercise 2 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- What state figures in the 145th line of our database?
SELECT 
	state 
FROM birdstrikes
LIMIT 144,1;
-- Answer 2: Tennessee

-- Exercise 3 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- What is flight_date of the latest birstrike in this database?
SELECT 
	flight_date 
FROM birdstrikes 
ORDER BY flight_date DESC 
LIMIT 1;
-- Answer 3: 2000-04-18

-- Exercise 4 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- What was the cost of the 50th most expensive damage?
SELECT 
	DISTINCT cost 
FROM birdstrikes 
ORDER BY cost DESC 
LIMIT 49,1;
-- Answer 4: 5345

-- Exercise 5 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- What state figures in the 2nd record, if you filter out all records which have no state and no bird_size specified?
SELECT 
	state
    ,bird_size
FROM birdstrikes 
WHERE bird_size IS NOT NULL 
	AND state IS NOT NULL 
    AND state <> ""
LIMIT 1,1;
-- Answer 5: Colorado

-- Exercise 6 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- How many days elapsed between the current date and the flights happening in week 52, for incidents from Colorado? (Hint: use NOW, DATEDIFF, WEEKOFYEAR)
SELECT
	state
	,DATE(NOW())  AS date_current
    ,flight_date
    ,WEEKOFYEAR(flight_date) AS week_of_flight_date
    ,DATEDIFF(NOW(), flight_date) AS day_diff
FROM birdstrikes
WHERE WEEKOFYEAR(flight_date) = 52
	AND state = "Colorado";
-- Answer 6: 7946