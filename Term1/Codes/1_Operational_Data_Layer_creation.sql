
# ---------------------------------------------------------------------- #
#  Data Engineering 1 - Term Project 1                                   # 
#  Created by: Viktória Kónya                                            #
#  Semester: 2021 Fall                                                   #
# ---------------------------------------------------------------------- #

# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #
#  OPERATIONAL DATA LAYER CREATION                                       #
#  What the code does:                                                   #
#        1. Creates a new schema                                         #
#        2. Creates empty shell tables                                   #
#        3. Adds foraign key to the empty tables                         #
#        4. Loads data to the tables from external .csv files            #
#  Notes:                                                                #
#  Due to the size of the datasets the query timeout needs to be set to  #
#  180. For this please go to Edit -> Preferences ->  SQL Editor tab and #
#  set the timeout limit to 180 before executing the code.               #
# ---------------------------------------------------------------------- #
# ---------------------------------------------------------------------- #

# ---------------------------------------------------------------------- #
#  1. Create new schema                                                  #
# ---------------------------------------------------------------------- #

-- Change default timeout
SHOW SESSION VARIABLES LIKE '%wait_timeout%'; 
SET @@GLOBAL.wait_timeout=600;

-- Change time zone 
SET global time_zone = '-5:00'; 
-- SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
-- SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
-- SET SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- Drop existing schema
DROP SCHEMA IF EXISTS mavenfuzzyfactorydb;

-- Create schema
CREATE SCHEMA mavenfuzzyfactorydb;

-- Switch to schema
USE mavenfuzzyfactorydb;



# ---------------------------------------------------------------------- #
#  2. Create empty shell for the tables                                  #
# ---------------------------------------------------------------------- #

-- Create an empty shell for 'website_sessions' table 
DROP TABLE IF EXISTS website_sessions;

CREATE TABLE website_sessions
(
	website_session_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	created_at TIMESTAMP NOT NULL,
	user_id BIGINT UNSIGNED NOT NULL,
	is_repeat_session SMALLINT UNSIGNED NOT NULL, 
	utm_source VARCHAR(12), 
	utm_campaign VARCHAR(20),
	utm_content VARCHAR(15), 
	device_type VARCHAR(15), 
	http_referer VARCHAR(30),
	
    CONSTRAINT PK_website_sessions PRIMARY KEY (website_session_id)
) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;
  
  
-- Create an empty shell for 'website_pageviews' table
DROP TABLE IF EXISTS website_pageviews;

CREATE TABLE website_pageviews  
(
	website_pageview_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	created_at TIMESTAMP NOT NULL,
	website_session_id BIGINT UNSIGNED NOT NULL,
	pageview_url VARCHAR(50) NOT NULL,
    
	CONSTRAINT PK_website_pageviews PRIMARY KEY (website_pageview_id)
) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;
  
  
-- Create an empty shell for 'products' table
DROP TABLE IF EXISTS products ;

CREATE TABLE products  
(
	product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	created_at TIMESTAMP NOT NULL,
	product_name VARCHAR(50) NOT NULL,
    
	CONSTRAINT PK_products PRIMARY KEY (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;


-- Create an empty shell for 'orders' table
DROP TABLE IF EXISTS orders;

CREATE TABLE orders  
(
	order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	created_at TIMESTAMP NOT NULL,
	website_session_id BIGINT UNSIGNED NOT NULL,
	user_id BIGINT UNSIGNED NOT NULL,
	items_purchased SMALLINT UNSIGNED NOT NULL,
  
	CONSTRAINT PK_orders PRIMARY KEY (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=UTF8MB4;


-- Create an empty shell for 'order_items' table
DROP TABLE IF EXISTS order_items ;

CREATE TABLE order_items  
(
	order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	created_at TIMESTAMP NOT NULL,
	order_id BIGINT UNSIGNED NOT NULL,
	product_id BIGINT UNSIGNED NOT NULL,
	price_usd DECIMAL(6,2) NOT NULL,
	cogs_usd DECIMAL(6,2) NOT NULL,
    
	CONSTRAINT PK_order_items PRIMARY KEY (order_item_id)
);


-- Create an empty shell for 'order_item_refunds' table
DROP TABLE IF EXISTS order_item_refunds;

CREATE TABLE order_item_refunds 
(	
	order_item_refund_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	created_at TIMESTAMP NOT NULL,
	order_item_id BIGINT UNSIGNED NOT NULL,
	order_id BIGINT UNSIGNED NOT NULL,
	refund_amount_usd DECIMAL(6,2) NOT NULL,
    
	CONSTRAINT PK_order_item_refunds PRIMARY KEY (order_item_refund_id)
);


# ---------------------------------------------------------------------- #
#  3. Add FOREIGN_KEY constraint to tables                               #
# ---------------------------------------------------------------------- #

-- website_sessions (PK: website_session_id) - website_pageviews (FK: website_session_id) relationship
ALTER TABLE website_pageviews  ADD CONSTRAINT FK_website_pageviews_website_sessions
	FOREIGN KEY (website_session_id) REFERENCES website_sessions (website_session_id) ;

-- website_sessions (PK: website_session_id) - orders (FK: website_session_id) relationship
ALTER TABLE orders  ADD CONSTRAINT FK_orders_website_sessions
	FOREIGN KEY (website_session_id) REFERENCES website_sessions (website_session_id) ;

-- products (PK: product_id) - order_items (FK: product_id) relationship
ALTER TABLE order_items  ADD CONSTRAINT FK_order_items_products
	FOREIGN KEY (product_id) REFERENCES products (product_id) ;
  
-- orders (PK: order_id) - order_items (FK: order_id) relationship
ALTER TABLE order_items  ADD CONSTRAINT FK_order_items_orders
	FOREIGN KEY (order_id) REFERENCES orders (order_id) ;
    
-- order_items (PK: order_item_id) - order_item_refunds (FK: order_item_id) relationship
ALTER TABLE order_item_refunds  ADD CONSTRAINT FK_order_item_refunds_order_items
	FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id) ;
    
-- orders (PK: order_id) - order_item_refunds (FK: order_id) relationship
ALTER TABLE order_item_refunds  ADD CONSTRAINT FK_order_item_refunds_orders
	FOREIGN KEY (order_id) REFERENCES orders (order_id) ;


# ---------------------------------------------------------------------- #
#  3. Insert data for the tables from external .csv files                #
# ---------------------------------------------------------------------- #

-- Insert data for 'website_sessions' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/website_sessions.csv'
INTO TABLE website_sessions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(	
	website_session_id,
	created_at,
	user_id,
	is_repeat_session, 
	@utm_source, 
	@utm_campaign,
	@utm_content, 
	@device_type, 
	@http_referer
)
SET 
	utm_source = nullif(@utm_source, ''),
	utm_campaign = nullif(@utm_campaign, ''),
 	utm_content = nullif(@utm_content, ''),   
  	device_type = nullif(@device_type, ''),  
	http_referer = nullif(@http_referer, '')
;
 
 
-- Insert data for 'website_pageviews' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/website_pageviews.csv'
INTO TABLE website_pageviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(	 
	website_pageview_id,
	@created_at,
	@website_session_id,
	@pageview_url
)
SET 
	created_at = nullif(@created_at, ''),
	website_session_id = nullif(@website_session_id, ''),
 	pageview_url = nullif(@pageview_url, '')
;
 

-- Insert data for 'products' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(	 
  product_id,
  created_at,
  product_name
);
 
 
-- Insert data for 'orders'
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(	 
  order_id,
  @created_at,
  @website_session_id,
  @user_id,
  @items_purchased
)
SET 
	created_at = nullif(@created_at, ''),
	website_session_id = nullif(@website_session_id, ''),
 	user_id = nullif(@user_id, ''),
	items_purchased = nullif(@items_purchased, '')
;


-- Insert data for 'order_items' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(	 
	order_item_id,
	@created_at,
	@order_id,
	@product_id,
	@price_usd,
	@cogs_usd
)
SET 
	created_at = nullif(@created_at, ''),
	order_id = nullif(@order_id, ''),
 	product_id = nullif(@product_id, ''),
	price_usd = nullif(@price_usd, ''),
 	cogs_usd = nullif(@cogs_usd, '')
;


-- Insert data for 'order_item_refunds' table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_item_refunds.csv'
INTO TABLE order_item_refunds
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(	order_item_refund_id,
	@created_at,
    @order_item_id,
    @order_id,
    @refund_amount_usd)
 SET 
	created_at = nullif(@created_at, ''),
	order_item_id = nullif(@order_item_id, ''),
 	order_id = nullif(@order_id, ''),
	refund_amount_usd = nullif(@refund_amount_usd, '')
; 


