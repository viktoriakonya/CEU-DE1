
# ---------------------------------------------------------------------- #
#  Data Engineering 1 - Term Project 1                                   # 
#  Created by: Viktória Kónya                                            #
#  Semester: 2021 Fall                                                   #
# ---------------------------------------------------------------------- #

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #
#  ANALYTICAL DATA LAYER CREATION                                        #
#  What the code does:                                                   #
#  		1. Creates a Stored procedure for the load of the                #
#		   Sales performance table (order_sales_refunds)                 #
#  		2. Creates a Stored procedure for the load of the                #
#		   Website activity table (website_activity)                     #
#  		3. Executes the stored procedures                                #
#  		4. Creates a trigger for the update of the 2 tables              #
#  Notes:                                                                #
# ---------------------------------------------------------------------- #

-- Switch to schema
USE mavenfuzzyfactorydb;

# ---------------------------------------------------------------------- #
#  1. Sales performance table                                            #
#  Source tables:   orders, order_items, products, order_item_refunds    #
#  Level of detail: order_item_id                                        #
#  Purpose: analyze sales related KPIs, identify quality issues          #
# ---------------------------------------------------------------------- #

DROP PROCEDURE IF EXISTS CreateSalesPerformance;

DELIMITER //

CREATE PROCEDURE CreateSalesPerformance()
BEGIN

DROP TABLE IF EXISTS sales_performance;    

CREATE TABLE sales_performance AS
SELECT
	
    o.order_id,
    oi.order_item_id,
    
    -- time dimension 
    o.created_at as order_created_at_dttm,
	YEAR(o.created_at) as order_created_at_yr,
	MONTH(o.created_at) as order_created_at_mth,
	WEEK(o.created_at) as order_created_at_wk,
	LAST_DAY(o.created_at) as order_created_at_mth_end_dt,
    DATE_ADD(DATE(o.created_at), INTERVAL  -WEEKDAY(DATE(o.created_at)) DAY) AS order_created_at_wk_start_dt, -- starts with Monday

    -- product dimension
	oi.product_id, 
	oi.primary_product_id, -- product first added to the cart
    oi.is_primary_product, -- flag showing if product was first added to the cart
	p.product_name, -- name of the product 
	p2.product_name AS primary_product_name, -- name of the product first taken to the cart
    DATE(p.created_at) AS product_release_dt, -- date when the product was launched
     
	-- sales facts
	COALESCE(oi.price_usd, 0) AS price_usd,
    COALESCE(oi.cogs_usd, 0) AS cogs_usd,
    COALESCE(oi.price_usd, 0) - COALESCE(oi.cogs_usd, 0) AS margin_usd, 
     
    -- refunds dimension
	oir.order_item_refund_id as refund_id,
    oir.created_at as refund_created_at_dttm,
	CASE WHEN oir.order_item_refund_id IS NOT NULL THEN 1 ELSE 0 END AS is_refunded, -- flag showing if the item was refunded
    DATEDIFF(oir.created_at, o.created_at) AS  day_diff_order_refund, -- days between the order and the refund completion
	COALESCE(oir.refund_amount_usd, 0) AS refund_amount_usd
    
FROM 
		(select
		case when oi2.min_order_item_id is not null then 1 else 0 end as is_primary_product,
		oi3.product_id as primary_product_id,
		oi1.*

		from order_items oi1
        
		left join -- order_item_id of primary product
			(select
				order_id,
				min(order_item_id) as min_order_item_id
			from order_items
			group by order_id) oi2
			on oi1.order_item_id  = oi2.min_order_item_id

		left join -- product_id of primary product
			(select 
				order_id,
				product_id
				from order_items
				where order_item_id in (select min(order_item_id) as min_order_item_id from order_items group by order_id) 
				) oi3
			on oi1.order_id  = oi3.order_id) oi -- primary item information was added to the order_items table

INNER JOIN orders o
	ON o.order_id = oi.order_id

INNER JOIN products p
	ON oi.product_id = p.product_id
    
INNER JOIN products p2
	ON oi.primary_product_id = p2.product_id -- product information of the primary item
    
LEFT JOIN order_item_refunds oir
	ON oi.order_item_id = oir.order_item_id
    
ORDER BY o.order_id, oi.order_item_id, o.created_at
;

END //
DELIMITER ;




# ---------------------------------------------------------------------- #
#  2. Website activity                                                   #
#  Source tables:   orders, website_sessions, website_pageviews          #
#  Level of detail: website_session_id                                   #
#  Purpose: analyze website traffic,                                     #
# ---------------------------------------------------------------------- #


DROP PROCEDURE IF EXISTS CreateWebsiteActivity;

DELIMITER //

CREATE PROCEDURE CreateWebsiteActivity()
BEGIN

DROP TABLE IF EXISTS website_activity;    

CREATE TABLE website_activity  AS

SELECT
			ws.website_session_id,
			
			-- session information
			ws.created_at as session_created_at,
			YEAR(ws.created_at) AS session_created_at_yr,
			MONTH(ws.created_at) AS session_created_at_mth,
			WEEK(ws.created_at) AS session_created_at_wk,
			LAST_DAY(ws.created_at) AS session_created_at_mth_end,
			DATE_ADD(DATE(ws.created_at), INTERVAL  -WEEKDAY(DATE(ws.created_at)) DAY) AS session_created_at_wk_start, -- starts with Monday

			-- user behaviour
			ws.user_id,
			ws.is_repeat_session as is_repeat_user_session, -- flag showing if the session was the first session by the user
			
			-- campaign dimension
			ws.utm_source,
			ws.utm_campaign,
			ws.utm_content,
			ws.device_type,
			ws.http_referer,
			
			-- pageview dimension (aggregated to session level)
			wpv2.pageview_url AS lander_page_url, -- first visited url page (landing page)
			wpv.number_of_pages_visited, -- number of pages visited in the session
			wpv.is_cart_included, -- flag if product was put into the cart
			
			-- order information
			o.order_id,
            case when order_id is not null then 1 else 0 end as is_order_created

		FROM 
			website_sessions ws 

		INNER JOIN 
			(SELECT
				website_session_id,
				MIN(created_at) AS min_created_at, -- date of the first pageview
				COUNT(DISTINCT pageview_url) AS number_of_pages_visited, -- number of pages visited in the session
				MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS is_cart_included -- product was put into the cart
			from website_pageviews
			group by website_session_id
			order by website_session_id) wpv
			
			ON wpv.website_session_id = ws.website_session_id -- aggregated website_pageviews table
			
		LEFT JOIN 
			(SELECT
				website_session_id,
				pageview_url,
				created_at
			from website_pageviews) wpv2
			on wpv2.website_session_id = ws.website_session_id
			and wpv2.created_at = ws.created_at -- timestamp of the url is equal to the start of the session

		LEFT JOIN orders o
			ON ws.website_session_id = o.website_session_id

		ORDER BY  1,2
		-- LIMIT 10000
		;

END //
DELIMITER ;



# ---------------------------------------------------------------------- #
#  3. Execute stored procedures                                          #
# ---------------------------------------------------------------------- #

-- Sales performance table
CALL CreateSalesPerformance();

-- Test if load was successful
SELECT * FROM sales_performance;
SELECT count(1) as count FROM sales_performance;

-- Website activity table
CALL CreateWebsiteActivity();

-- Test if load was successful
SELECT * FROM website_activity;
SELECT count(1) as count FROM website_activity;


# ---------------------------------------------------------------------- #
#  4. Trigger for new refund information                                 #
# ---------------------------------------------------------------------- #

-- Create table for log
DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
    message VARCHAR(255) NOT NULL,
    processed_dttm DATETIME NOT NULL
);


-- Create trigger for sales_performance table
DROP TRIGGER IF EXISTS CreateOrderInsert; 

DELIMITER $$

CREATE TRIGGER CreateOrderInsert
AFTER INSERT 
ON order_items FOR EACH ROW
BEGIN
	
	-- log the refund id of the newley inserted refund
	-- INSERT INTO messages SELECT CONCAT('Trigger was executed. New order id was inserted into the sales_performance table.', NEW.order_id, NOW());
     
	INSERT INTO messages(message,processed_dttm)
	VALUES(CONCAT('Trigger was executed. New order id was inserted into the sales_performance table: ', NEW.order_id),NOW());
     
     -- Execute table code
			INSERT INTO sales_performance
			SELECT
				
				o.order_id,
				oi.order_item_id,
				
				-- time dimension 
				o.created_at as order_created_at_dttm,
				YEAR(o.created_at) as order_created_at_yr,
				MONTH(o.created_at) as order_created_at_mth,
				WEEK(o.created_at) as order_created_at_wk,
				LAST_DAY(o.created_at) as order_created_at_mth_end_dt,
				DATE_ADD(DATE(o.created_at), INTERVAL  -WEEKDAY(DATE(o.created_at)) DAY) AS order_created_at_wk_start_dt, -- starts with Monday

				-- product dimension
				oi.product_id, 
				oi.primary_product_id, -- product first added to the cart
				oi.is_primary_product, -- flag showing if product was first added to the cart
				p.product_name, -- name of the product 
				p2.product_name AS primary_product_name, -- name of the product first taken to the cart
				DATE(p.created_at) AS product_release_dt, -- date when the product was launched
				 
				-- sales facts
				COALESCE(oi.price_usd, 0) AS price_usd,
				COALESCE(oi.cogs_usd, 0) AS cogs_usd,
				COALESCE(oi.price_usd, 0) - COALESCE(oi.cogs_usd, 0) AS margin_usd, 
				 
				-- refunds dimension
				oir.order_item_refund_id as refund_id,
				oir.created_at as refund_created_at_dttm,
				CASE WHEN oir.order_item_refund_id IS NOT NULL THEN 1 ELSE 0 END AS is_refunded, -- flag showing if the item was refunded
				DATEDIFF(oir.created_at, o.created_at) AS  day_diff_order_refund, -- days between the order and the refund completion
				COALESCE(oir.refund_amount_usd, 0) AS refund_amount_usd
				
			FROM 
					(select
					case when oi2.min_order_item_id is not null then 1 else 0 end as is_primary_product,
					oi3.product_id as primary_product_id,
					oi1.*

					from order_items oi1
					
					left join -- order_item_id of primary product
						(select
							order_id,
							min(order_item_id) as min_order_item_id
						from order_items
						group by order_id) oi2
						on oi1.order_item_id  = oi2.min_order_item_id

					left join -- product_id of primary product
						(select 
							order_id,
							product_id
							from order_items
							where order_item_id in (select min(order_item_id) as min_order_item_id from order_items group by order_id) 
							) oi3
						on oi1.order_id  = oi3.order_id) oi -- primary item information was added to the order_items table

			INNER JOIN orders o
				ON o.order_id = oi.order_id

			INNER JOIN products p
				ON oi.product_id = p.product_id
				
			INNER JOIN products p2
				ON oi.primary_product_id = p2.product_id -- product information of the primary item
				
			LEFT JOIN order_item_refunds oir
				ON oi.order_item_id = oir.order_item_id
                
			WHERE  o.order_id = NEW.order_id
				
			ORDER BY o.order_id, oi.order_item_id, o.created_at
			;
				 
END$$




DROP TRIGGER IF EXISTS CreateOrderInsertWebsite; 

DELIMITER $$

CREATE TRIGGER CreateOrderInsertWebsite
AFTER INSERT 
ON order_items FOR EACH ROW FOLLOWS CreateOrderInsert
BEGIN
	
	-- log the refund id of the newley inserted refund
	-- INSERT INTO messages SELECT CONCAT('Trigger was executed. New order id was inserted into the website_activity table.', NEW.order_id, NOW());
	
    INSERT INTO messages(message,processed_dttm)
	VALUES(CONCAT('Trigger was executed. New order id was inserted into the website_activity table: ', NEW.order_id),NOW());
     
     -- Execute table code
	INSERT INTO website_activity			
	SELECT
             
			ws.website_session_id,
			
			-- session information
			ws.created_at as session_created_at,
			YEAR(ws.created_at) AS session_created_at_yr,
			MONTH(ws.created_at) AS session_created_at_mth,
			WEEK(ws.created_at) AS session_created_at_wk,
			LAST_DAY(ws.created_at) AS session_created_at_mth_end,
			DATE_ADD(DATE(ws.created_at), INTERVAL  -WEEKDAY(DATE(ws.created_at)) DAY) AS session_created_at_wk_start, -- starts with Monday

			-- user behaviour
			ws.user_id,
			ws.is_repeat_session as is_repeat_user_session, -- flag showing if the session was the first session by the user
			
			-- campaign dimension
			ws.utm_source,
			ws.utm_campaign,
			ws.utm_content,
			ws.device_type,
			ws.http_referer,
			
			-- pageview dimension (aggregated to session level)
			wpv2.pageview_url AS lander_page_url, -- first visited url page (landing page)
			wpv.number_of_pages_visited, -- number of pages visited in the session
			wpv.is_cart_included, -- flag if product was put into the cart
			
			-- order information
			o.order_id,
            case when order_id is not null then 1 else 0 end as is_order_created


		FROM 
			website_sessions ws 

		INNER JOIN 
			(SELECT
				website_session_id,
				MIN(created_at) AS min_created_at, -- date of the first pageview
				COUNT(DISTINCT pageview_url) AS number_of_pages_visited, -- number of pages visited in the session
				MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS is_cart_included -- product was put into the cart
			from website_pageviews
			group by website_session_id
			order by website_session_id) wpv
			
			ON wpv.website_session_id = ws.website_session_id -- aggregated website_pageviews table
			
		LEFT JOIN 
			(SELECT
				website_session_id,
				pageview_url,
				created_at
			from website_pageviews) wpv2
			on wpv2.website_session_id = ws.website_session_id
			and wpv2.created_at = ws.created_at -- timestamp of the url is equal to the start of the session

		LEFT JOIN orders o
			ON ws.website_session_id = o.website_session_id

		WHERE  o.order_id = NEW.order_id
            
		ORDER BY  1,2
		-- LIMIT 10000
		;


END$$



-- Activate trigger

-- Let's say that there is a customer who came via gsearch, and bought one toy. In its session he navihated from the home page to the the order confirmation page.
INSERT INTO website_sessions (website_session_id, created_at, user_id , is_repeat_session, utm_source , utm_campaign,utm_content , device_type, http_referer) VALUES(472880,'2015-03-19 10:38:16',386010,1,'gsearch','nonbrand','g_ad_1','mobile','https://www.gsearch.com');

INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1188999,'2015-03-19 10:38:16',472880,'/home');
INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1189001,'2015-03-19 10:39:15',472880,'/products');
INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1189002,'2015-03-19 10:39:21',472880,'/the-original-mr-fuzzy');
INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1189003,'2015-03-19 10:42:22',472880,'/cart');
INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1189004,'2015-03-19 10:43:11',472880,'/shipping');
INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1189005,'2015-03-19 10:43:34',472880,'/billing-2');
INSERT INTO website_pageviews (website_pageview_id,created_at,website_session_id,pageview_url) VALUES(1189006,'2015-03-19 10:47:45',472880,'/thank-you-for-your-order');

INSERT INTO orders (order_id ,created_at,website_session_id,user_id,items_purchased) VALUES(32314,'2015-03-19 10:47:45',472880,386010,1);
INSERT INTO order_items (order_item_id, created_at ,order_id, product_id,  price_usd, cogs_usd ) VALUES(40026,'2015-03-19 10:47:45',32314,1,49.99,19.49);

-- Check
SELECT * FROM sales_performance where order_item_id = 40026 or order_id = 32314;
SELECT * FROM website_activity where order_id = 32314; -- repeat user
SELECT * FROM messages;

SELECT count(1) FROM order_items; -- increased by 1 record
SELECT count(1) FROM orders; -- increased by 1 record
SELECT count(1) FROM website_sessions; -- increased by 1 record
SELECT count(1) FROM website_pageviews; -- increased by 7 records

SELECT count(1) FROM sales_performance; -- increased by 1 record
SELECT count(1) FROM website_activity; -- increased by 1 record




  
 
 
 
 
 
 
 
 
 
 
 
 
