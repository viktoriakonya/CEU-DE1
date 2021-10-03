
**Exercise 1**: Do the same with speed. If speed is NULL or speed < 100 create a “LOW SPEED” category, otherwise, mark as “HIGH SPEED”. Use IF instead of CASE!

``` sql
SELECT 
speed, 
IF(speed IS NULL OR speed<100, 'Low speed', 'High speed') AS speed_cat
FROM birdstrikes;
```
# 

**Exercise 2**:  How many distinct ‘aircraft’ we have in the database?

``` sql
SELECT 
COUNT(DISTINCT aircraft) AS aircraft_dist 
FROM birdstrikes;
```
**Answer 2**: 3

#

**Exercise 3**: What was the lowest speed of aircrafts starting with ‘H’

``` sql
SELECT
MIN(speed) as min_speed
FROM birdstrikes
WHERE aircraft LIKE "H%" 
AND speed IS NOT NULL;
```
**Answer 3** : 9

#

**Exercise 4**: Which phase_of_flight has the least of incidents?

``` sql
SELECT
	phase_of_flight
	,count(1) as count
FROM birdstrikes
GROUP BY phase_of_flight 
ORDER BY count
LIMIT 1;
```

**Answer 4**: Taxi with 2 incidents

# 

**Exercise 5**:  What is the rounded highest average cost by phase_of_flight?

``` sql
SELECT 
	phase_of_flight
    ,round(avg(cost)) as avg_cost
FROM birdstrikes
GROUP BY phase_of_flight
ORDER BY avg_cost DESC
LIMIT 1;
```

**Answer 5**: 54673 (Climb)

# 

**Exercise 6**:  What the highest AVG speed of the states with names less than 5 characters?

``` sql
SELECT 
	state,
    avg(speed) as avg_speed
FROM birdstrikes
WHERE LENGTH(state) <=5 
	AND state IS NOT NULL
GROUP BY state
ORDER BY avg_speed DESC
LIMIT 1;
```

**Answer 6**: 2862.5000 (Iowa state)
