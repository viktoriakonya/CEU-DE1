## E-commerce Marketing and Website Analysis

## Table of Contents  
1. [Overview](#Overview)  
2. [Operational layer](#Operational_layer)  
3. [Analytical questions](#Analytical_questions)  
4. [Analytical layer and ETL](#Analytical_layer_and_ETL)  
5. [Data marts and views](#Data_marts_and_views)  


<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- OVERVIEW--------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->

<a name="Overview"/>

## Overview

In my Term 1 project, I am going to use a fictitious e-commerce company's database which is provided by [Maven Analytics](https://www.mavenanalytics.io/course/advanced-mysql-data-analysis). The database contains typical e-commerce records in 6 tables which includes website activity, products and order refund related information.The company sells toys on its website and aims to boost its sellings by running paid online marketing campaigns. At the same time, it collects information about the customers' online activity as well as typical sales related data. In my project, I aim going to create analytical storage and datamarts which can de used to 1) measure the performance of the company's sales and 2) measure and evaluate website activity. In our analysis, we are going to restrict the scope for the 2014 and 2015 years due to the size of the tables.

First, let's take a look at the tables of the database:
1. **Orders** and **Order_items** are the key tables to measure the sales performance of the company. The tables contain information about the items ordered, about the revenues and **Orders** table contains the identifier of the website session in which the customer placed the order.
2. **Order_items_refunds** table contains the information about customers who complained and were issued a refund.
3. **Products** table contains the list of products of the company with the date when they were launched.
4. **Website_sessions** table contains session level information about the sources of the traffic and user behaviour.
     * The key fields of the table are the UTM (Urchin Tracking Module) parameters which are associated with the user session. These parameters are used to measure the paid marketing activity by adding tracking parameters to the URL. The **utm_source** shows where the traffic is coming from (empty if it is not driven by paid campaign - so called direct traffic). The **utm_campaign** and the **utm_content** let us know what call-to-action brought in traffic. 
     * The **device_type** captures the type of device that was used by the user in the session. 
     * The **http_referer** shows the referring domain.
6. **Website_pageviews** table contains the log of pageviews of pages that the users visited when they were at e-commerce website. 

The datasets can be found [here](https://github.com/viktoriakonya/DE1/tree/main/Term1/Datasets).

<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- OPERATIONAL LAYER ----------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->

<a name="Operational_layer"/>

## Operational layer

The data files of the company were first subsetted to include only 2014 and 2015 year information and then loaded to the schema from csv files.

The following chart shows the ER diagram of the database:

<img height= 400 src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/ER_Diagram.JPG">


The **orders** table is the key table as it can be extended with more granular information about both the website activity (**website_sessions**, **website_pageviews**) and the orders (**order_items**, **order_items_refund**, **products**). Later, in the creation of the analytical storage instead of creating one denormalized table by joining all 6 tables I decided to create two tables for the analytical layer, where the first table will focus on the orders and sales related information (**sales_performance**), and the second table will be used to track website traffic (**website_activity**). The main reason for this is that the subject and the content of the tables are easily interpretable and better fits our analysis. The drawback of this approach is that the two tables in the analytical layer need to be combined if we would like to, for example, analyze the profitability of certain online campaigns.

<br/>

After we have executed the operational layer, let's look at each table to better understand the content of them:

When a user enters a session, he is typically landed on either the home page or on any of the lander pages. When he clicks through the pages, his website activity information is tracked and logged into the **website_pageviews** table. 

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/tables1.JPG">

His session information is stored in the **website_sessions** table. From the UTM parameters we can see that which paid online campain brought in the user, the type of the campaign and we can also see that what device was used by the user when he entered the session.

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/tables2.JPG">

From the website_pageviews table we can see that this user purchased one product. The information of the order is stored in the **orders** table showing which session generated the order and which user made the purchase.

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/tables3.JPG">

The **order_items** table shows the product level information of the order as well as the revenue related information.

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/tables4.JPG">

Finally, if the customer was unsatisfied with the product and was issued a refund, it is logged into the **order_item_refunds** table.

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/tables5.JPG">

\
The code for the Operational layer can be found [here](https://github.com/viktoriakonya/DE1/blob/main/Term1/Codes/1_Operational_Data_Layer_creation.sql).\
The model file can be found [here](https://github.com/viktoriakonya/DE1/blob/main/Term1/Codes/ER_diagram.mwb).	
  
*Technical note*: Because of the size of the datasets, the session timeout limit should might be increased for the execution of the operational layer.

	
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- ANALYTICAL QUESTIONS -------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->

<a name="Analytical_questions"/>

## Analytical questions

Our analytical questions will cover two areas. Firstly, we would like to answer questions that are typically raised by Sales and Reporting divisions. Secondly, we would like to supply information about the website traffic and paid campaigns which can be used by the Website Management.

1. Sales & Marketing related questions:
    * Let's create a monthly updated data mart that contains the month end figures (most important sales KPIs) by product after the 4th product release (2014-02-05). 
        * What was the most sold product in the last month of the examined period (2015-03)? 
        * Which product had the highest refund rate in the last month of the examined period (2015-03)? 
        * How many days on average passed between the order and the refund issued in the past 3 months (2015-01 - 2015-03)?
        * Which month did the we make the highest margin in 2014?
    * Let's create a view showing the primary products added to the cart and the cross-sold products on yearly basis after the 4th product release (2014-02-05).
        * Which product was more often put into the cart first in 2014 and in 2015? 
        * Which are the products that were sold together most often?
    
2. Website traffic related questions:
    * Let's create a view which summarizes the sources of paid traffic by UTM source and UTM campaign since the socialbook (desktop targeted) campaign was introduced (2014-08-18).
        * Which campaign was the main source of the traffic in 2014 and in 2015? 
        * Was socialbook a successfull campiagn in terms of the proportion of the bounced sessions (proportion of sessions where the user wisited only one website page)?
    * Let's create a weekly updated data mart that we can use to track paid website traffic. 
    	* To which campaign should allocate more resources based on the past 3 weeks' traffic information? Shall we differentiate based on the device type? 
        * Which campaign has the highest session to order conversion rate in the last examined week?
    * Let's create a view showing the traffic by landing pages in 2014 and 2015.
        * Which were the top landing pages in 2014 and 2015?

  
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- ANALYTICAL LAYER     -------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->

<a name="Analytical_layer_and_ETL"/>

## Analytical layer and ETL

My e-commerce data warehouse will consist of two tables. The first, **sales_performance** table will contain product, revenue and refund related information of the items ordered and can mainly used for Sales and Marketing analytics. The second, **website_activity** table will contain session level information mainly focusing on the sources of traffic as well as on paid campaign performance.

### 1. sales_performance table:
The analytical data store for the sales related information was created in the **sales_performance** table. The **sales_performance** table contains a denormalized snapshot of the combined **order_item**, **orders**, **order_items_refund** and **products** tables. The initial creation of the table was embedded in a stored procedure which was executed to create the data store. In order to transfer the information of the new records from the operational tables, after insert trigger was created which is activated when a new insert is executed into the **order_items** table.

#### Extract:
The order_items, orders, order_items_refund and products tables from the operational layer were joined to create the **sales_performance** table. **orders** and **products** tables were merged to the **order_items** table by inner join, while **order_items_refunds** table was connected by left join as is contains a subset of the items ordered. Note that **products** table was joined twice, first using the **product_id** and second time using the **product_id** of the primary product that was first added to the cart.

The following table contains the list of fields of the table:

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/analytical1.JPG">

#### Transform:
For analytical and reporting purposes, the creation of the order date (**created_at**) field was transformed to represent different periodicity (year, month, week, month end, week start date). The identifier of the primary product (**primary_product_id**) and the flag showing if a particular product (**is_primary_product**) was first added to the cart were created using a subquery and then were joined back to the **order_items** table. Also, the product release date (**product_release_dt**) was transformed to date format from **created_at** filed of the the **products** table. For profitability analysis, the margin (**margin_usd**) was also calculated as the difference of the price and the cogs. In case of refunds, the **is_refunded** flag was added showing if the order was refunded, as well as the **day_diff_order_refund** field which shows that how many days have passed between the order and when the refund was issued.

#### Load 
The CreateOrderInsert() trigger will load a new line to the **sales_performance** table once an insert operation is executed on the **order_items** table. The successful execution of the trigger is logged into the **messages** table with the identifier of the newly inserted order.


### 2. website_activity table:
Similar to the **sales_performance** table, the analytical data store for the website traffic related information was created in the **website_activity** table. The **website_activity** table contains a denormalized snapshot of the combined **website_sessions**, **website_pageviews** and **orders** tables. The initial creation of the table was also embedded in a stored procedure which was executed to create the data store. In order to transfer the information of the new records from the operational table to the **website_activity**, after insert trigger was created for the **website_activity** table that is also activated when new insert is executed into the **order_items** table.

#### Extract:
The **website_sessions**, **website_pageviews** and **orders** tables from the operational layer were joined to create the **website_activity** table. The **website_pageviews** table was first aggregated to **session_id** level in a subquery, first of all to decrease the size of the table, and second because the exact website pages visited by a customer are not relevant from analytical perspective. The aggregated **website_pageviews** and the **orders** tables were then merged to the **website_sessions**  by inner join. 

The following table contains the list of fields of the table:

<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/analytical2.JPG">


#### Transform:
The session creation date **created_at** was transformed to represent different periodicity (year, month, week, month end, week start date). From the aggregeted **website_pageviews** table the following derived fields were added to the table: **lander_page_url** which is the url of the page where the user was landed when he started the session, the **number_of_pages_visited** which shows how many pages were visited by the user in a particular session and the **is_cart_included** which shows if the user has put any products to its cart in the session. From the **orders** table I only added the a flag which shows if the user made a purchase in the session (**is_order_created**).

#### Load 
The CreateOrderInsertWebsite() trigger will load a new line to the **website_activity** table once an insert operation is executed on the **order_items** table. The successful execution of the trigger is logged into the **messages** table with the identifier of the newly inserted order.

<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- DATA MARTS ------------------------------------------------------------------------------------------------------------------------------------------------------------ -->
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->

<a name="Data_marts_and_views"/>

## Data marts and views
    
To answer the analytical questions, datamarts were created containing aggregated information and / or subsets of the data storage which can be used to supply information for certain divisions of the company, such as reporting. The data marts were created with scheduled eventswith different periodicity (for testing purposes the events were scheduled for the next miunute)

The code of the datamarts can be found here: <>
    
#### 1. Data mart showing the month end figures after the 4th product release
    * What is the most sold product in the last month of the examined period (2015-03)? 
    * Which product had the highest refund rate in the last month of the examined period (2015-03)? - categorize
    * How many days on average passes between the order and the refund issued?
	* Which month did the we make the highest margin in 2014?
    
<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/sales1.JPG">

If we filter for 2015-03 month end then we can see that product 1, 'The Original Mr. Fuzzy' was the most sold product in that month with 865 sales, while the 'Forever Love Bear' had the highest refund rate with 9.8%.
If we look at the time seties of the month end figures, we can see that the refuds are issued around 9 days after the purchase.
When we aggregate the data to monthly level, we can see that 2014-12 had the highest margin in 2014 with 91.857 USD.
    
#### 2. View showing the primary products added to the cart and cross-sold products by year
      * Which product was more often put into the cart first in 2014 and in 2015? 
      * Which are the products that were sold together with the highest sales?  
    
<img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/sales3.JPG">    
    
We can see that product 1, 'The Original Mr. Fuzzy' was most often added to the cart first in both 2014 and in the first 3 months of 2015 with 6934 and 1989 sales respectively.
Regarding the tied products, 'The Hudson River mini bear' was most often purchased together with the 'The Original Mr. Fuzzy' first taken to the cart.
(For this view it was checked in advance that maximum 2 products were in one order in the 2 examined years).

#### 3. View summarizing the sources of paid traffic by UTM source and UTM campaign since the socialbook (desktop targeted) was introduced (2014-08-18).
	* Which campaign was the main source of the traffic in 2014 and in 2015? 
	* Was socialbook a successfull campiagn in terms of the proportion of the bounced sessions (proportion of sessions where the user wisited only one website page)?
	
 <img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/traffic1.JPG">    
     
We can see that the gsearch nonbrand campaign brought in the most traffic in both years. 
It seems that the socialbook desktop targeted campaign was not an effective campaign as the proportion of the bounced user sessions are considerably higher then in other campaigngs with almost 70% of the users visiting only one website page.
    
 #### 4. Data mart showing the weekly paid website traffic information
	* Which campaign should we bid up based on the past 3 weeks' traffic information? Shall we differenciate based on the device type? 
        * Which campaign has the highest session to order conversion rate in the last examined week?
    
 <img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/traffic2.JPG"> 

Based on the weekly figures, the gsearch nonbrand campaign is contantly the top source of the traffic.
We can also see that in the gsearch nonbrand campaign, the traffic is unevenly distributed by device type with the desktop targeted generating the vast majorority of the incoming traffic. We can conclude that the gsearch nonbrand desktop targeted campaign should be in the center of our focus.
Regarding the session to order conversion rates (number of sessions where the user created an order), we can also see that there is considerably difference based on the device type with an average 10% conversion rate in case of the desktop targeted and below 5% conversion rate in case of the mobile targeted campaign. On the 2015-03-16 week the gsearch brand desktop targeted campaign had the highest conversion rate with 10.7%.

##### View showing the traffic by landing pages in 2014 and 2015.
	* Which were the top landing pages in 2014 and 2015?
	
 <img  src="https://github.com/viktoriakonya/DE1/blob/main/Term1/Pictures/traffic3.JPG"> 
	
In 2014 the most users were landed on the /home page while in the first 3 months of 2015 more userd were landed on the /lander-5.
	
	
	
	
	
	
	
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->
<!-- CHECK EXECUTION  ------------------------------------------------------------------------------------------------------------------------------------------------------ -->
<!-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- -->

