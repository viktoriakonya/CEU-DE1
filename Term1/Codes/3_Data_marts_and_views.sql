
# ---------------------------------------------------------------------- #
#  Data Engineering 1 - Term Project 1                                   # 
#  Created by: Viktória Kónya                                            #
#  Semester: 2021 Fall                                                   #
# ---------------------------------------------------------------------- #

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #
#  DATA MART AND VIEW CREATION                                           #
#  What the code does:                                                   #
#  		1. Creates Monthly Sales KPI Data Mart with Event trigger        #
#  		2. Creates View for cross-sold products                          #
#  		3. Creates Weekly Data Mart for paid traffic tracking with Event #
#          trigger                                                       #
#  		4. Creates View for top landing pages                            #
#  Notes:                                                                #
# ---------------------------------------------------------------------- #

-- Switch to schema
USE mavenfuzzyfactorydb;

-- Set scheduler
SET GLOBAL event_scheduler = ON;

# ---------------------------------------------------------------------- #
#  1. Sales KPI Data Mart - Monthly                                      #
#  Purpose: Show month end figures                                       #
# ---------------------------------------------------------------------- #

DROP PROCEDURE IF EXISTS CreateSalesKPIMonthly;

DELIMITER //

CREATE PROCEDURE CreateSalesKPIMonthly()

BEGIN

DROP TABLE IF EXISTS sales_kpi_monthly;

CREATE TABLE sales_kpi_monthly AS

select
	order_created_at_yr as 'Order year',
	order_created_at_mth_end_dt as 'Order month',
    product_name as 'Product name',
    
    count(DISTINCT order_id) as 'Number of orders',
    sum(margin_usd) as 'Margin $',
    sum(is_refunded) as 'Number of refunded items',
    sum(refund_amount_usd) as 'Refund amount',
    sum(is_refunded)  / count(DISTINCT order_item_id) as 'Refund rate',
	sum(refund_amount_usd)  / sum(price_usd) as 'Refund rate $',
    avg(day_diff_order_refund) as 'Average days between order and refund'

from sales_performance
where date(order_created_at_dttm) > '2014-02-05'
group by 1,2,3
order by 1,2,3,4 desc;

END //
DELIMITER ;


DROP EVENT IF EXISTS CreateSalesKPIMonthlyEvent;

DELIMITER $$

CREATE EVENT CreateSalesKPIMonthlyEvent
-- ON SCHEDULE EVERY 1 MONTH
ON SCHEDULE EVERY 1 MINUTE 
STARTS CURRENT_TIMESTAMP
-- ENDS CURRENT_TIMESTAMP + INTERVAL 24 MONTH
ENDS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
	BEGIN
		INSERT INTO messages(message,processed_dttm)
		VALUES('Scheduled event was executed for the sales_kpi table.',NOW());

		CALL CreateSalesKPIMonthly(); 
        
	END$$
DELIMITER ;

SHOW EVENTS;


-- Check table
select * from messages;    
select * from sales_kpi_monthly;


# ---------------------------------------------------------------------- #
#  2. Cross sold products - Yearly                                       #
# ---------------------------------------------------------------------- #

DROP PROCEDURE IF EXISTS CreateCrossSoldYearly;

DELIMITER //

CREATE PROCEDURE CreateCrossSoldYearly()

BEGIN

DROP TABLE IF EXISTS cross_sell_yearly;

CREATE TABLE cross_sell_yearly AS
(
select
	order_created_at_yr as 'Year',
    primary_product_name as 'Primary product',
	case 
		when product_1 = 1 then 'The Original Mr. Fuzzy'
		when product_2 = 1 then 'The Forever Love Bear'
        when product_3 = 1 then 'The Birthday Sugar Panda'
		when product_4 = 1 then 'The Hudson River Mini bear'
        end as 'Tied product',

    count(distinct order_id) as 'Number of orders',
    sum(margin) as 'Margin'
	
from

		(
		select
			order_created_at_yr,
			order_id,
			primary_product_name,
			
			sum(case when primary_product_id <> product_id and product_id = 1 then 1 else 0 end) as product_1,
			sum(case when primary_product_id <> product_id and product_id = 2 then 1 else 0 end) as product_2,
			sum(case when primary_product_id <> product_id and product_id = 3 then 1 else 0 end) as product_3,
			sum(case when primary_product_id <> product_id and product_id = 4 then 1 else 0 end) as product_4,
			-- count(order_item_id) number_of_items,
			sum(margin_usd) as margin  
			
			from  sales_performance
			where order_created_at_mth_end_dt >= '2014-02-05'
			group by 1,2,3
			
		) sales_performance2

  group by 1,2,3
  order by 1, 4 desc

);

END //
DELIMITER ;


DROP EVENT IF EXISTS CreateCrossSoldYearlyEvent;

DELIMITER $$

CREATE EVENT CreateCrossSoldYearlyEvent
-- ON SCHEDULE EVERY 1 YEAR
ON SCHEDULE EVERY 1 MINUTE 
STARTS CURRENT_TIMESTAMP
-- ENDS CURRENT_TIMESTAMP + INTERVAL 24 MONTH
ENDS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
	BEGIN
		INSERT INTO messages(message,processed_dttm)
		VALUES('Scheduled event was executed for the sales_kpi table.',NOW());

		CALL CreateCrossSoldYearly(); 
        
	END$$
DELIMITER ;

SHOW EVENTS;

-- Check table
select * from messages;    
select * from cross_sell_yearly;



# ---------------------------------------------------------------------- #
#  3. Top traffic sources and bounced sessions - Weekly                  #
# ---------------------------------------------------------------------- #


DROP PROCEDURE IF EXISTS CreateWebsiteTrafficWeekly;

DELIMITER //

CREATE PROCEDURE CreateWebsiteTrafficWeekly()

BEGIN

DROP TABLE IF EXISTS website_traffic_weekly;

CREATE TABLE website_traffic_weekly AS

select
	session_created_at_yr as 'Year',
	session_created_at_wk_start as 'Week',
    utm_source as 'UTM source',
    utm_campaign as 'UTM campaign',
    -- http_referer,
    
	count(distinct website_session_id) as 'Sessions total',
	count(distinct order_id) as 'Orders total',
	count(distinct order_id)  /
	count(distinct website_session_id) as 'Session to order conversion rate total',
	sum(case when number_of_pages_visited = 1 and order_id is null then 1 else 0 end) as 'Number of bounced user sessions',
    sum(case when number_of_pages_visited = 1 then 1 else 0 end) / count(distinct website_session_id) as 'Bounce rate',
    
	count(distinct case when device_type = 'desktop' then website_session_id else null end) as 'Sessions desktop',
	count(distinct case when device_type = 'desktop' then order_id else null end) as 'Orders desktop',
	count(distinct case when device_type = 'desktop' then order_id else null end)  /
	count(distinct case when device_type = 'desktop' then website_session_id else null end) as 'Session to order conversion rate desktop',
 
 	count(distinct case when device_type = 'mobile' then website_session_id else null end) as 'Sessions mobile',
	count(distinct case when device_type = 'mobile' then order_id else null end) as 'Orders mobile',
	count(distinct case when device_type = 'mobile' then order_id else null end)  /
		count(distinct case when device_type = 'mobile' then website_session_id else null end) as 'Session to order conversion rate mobile'
from website_activity
where utm_source is not null -- exclude direct traffic
and session_created_at_wk_start > '2014-08-17'
group by 1,2,3
order by 1, 4 desc;

END //
DELIMITER ;



DROP EVENT IF EXISTS CreateWebsiteTrafficWeeklyEvent;

DELIMITER $$

CREATE EVENT CreateWebsiteTrafficWeeklyEvent
-- ON SCHEDULE EVERY 1 WEEK
ON SCHEDULE EVERY 1 MINUTE 
STARTS CURRENT_TIMESTAMP
-- ENDS CURRENT_TIMESTAMP + INTERVAL 24 MONTH
ENDS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
	BEGIN
		INSERT INTO messages(message,processed_dttm)
		VALUES('Scheduled event was executed for the website_traffic_weekly table.',NOW());

		CALL CreateWebsiteTrafficWeekly(); 
        
	END$$
DELIMITER ;

SHOW EVENTS;

select * from messages;    
select * from website_traffic_weekly;

# ---------------------------------------------------------------------- #
#  3. Top landing pages                                                  #
# ---------------------------------------------------------------------- #

DROP VIEW IF EXISTS top_landing_pages;

CREATE VIEW top_landing_pages AS
select 
	session_created_at_yr as 'Year',
	lander_page_url as 'Lander page',
 	count(distinct website_session_id ) as 'Number of sessions'
from website_activity
where -- utm_source = 'gsearch'
-- and utm_campaign = 'brand'
 website_session_id <> '472880' -- manually inserted session
group by 1,2
order by 1, 3 desc;
    
select * from top_landing_pages;
 