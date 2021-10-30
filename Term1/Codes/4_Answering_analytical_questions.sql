
# ---------------------------------------------------------------------- #
#  Data Engineering 1 - Term Project 1                                   # 
#  Created by: Viktória Kónya                                            #
#  Semester: 2021 Fall                                                   #
# ---------------------------------------------------------------------- #

-- What was the most sold product in the last month of the examined period (2015-03)? 
-- Which product had the highest refund rate in the last month of the examined period (2015-03)? 
-- How many days on average passed between the order and the refund issued in the past 3 months (2015-01 - 2015-03)?
SELECT *
FROM sales_kpi_monthly
WHERE `Order month` = '2015-03-31';
-- Product 1, 'The Original Mr. Fuzzy' was the most sold product in that month with 865 sales
-- 'Forever Love Bear' had the highest refund rate with 9.8%
-- If we look at the time series of the month end figures, we can see that the refuds are issued around 9 days after the purchase.

-- Which month did the we make the highest margin in 2014?
SELECT
	`Order month`,
    sum(`Margin $`) as `Margin $`
FROM sales_kpi_monthly
WHERE `Order year` = 2014
GROUP BY 1
ORDER BY 2 desc;
-- 2014-12 was the month with the highest margin


-- Which product was more often put into the cart first in 2014 and in 2015? 
-- Which are the products that were sold together with the highest sales? 
SELECT 
	*
FROM cross_sell_yearly;
-- Product 1, 'The Original Mr. Fuzzy' was most often added to the cart first in both 2014 and in the first 3 months of 2015 with 6934 and 1989 sales respectively.
-- The 'The Hudson River mini bear' was most often purchased together with the 'The Original Mr. Fuzzy' first taken to the cart. 


-- To which campaign should the company allocate more resources based on the past 3 weeks' traffic information? Shall we differentiate based on the device type?
-- Which campaign has the highest session to order conversion rate in the last examined week?
SELECT 
	`Week`,
    `UTM source`,
    `UTM campaign`,
    `Sessions total`,
	`Orders total`,
	`Session to order conversion rate total`,
    
	`Sessions desktop`,
	`Orders desktop`,
	`Session to order conversion rate desktop`,
 
 	`Sessions mobile`,
	`Orders mobile`,
	`Session to order conversion rate mobile`
FROM website_traffic_weekly
where `Week` >= '2015-03-02'
order by 1,4 desc;

SELECT 
	`Week`,
    `UTM source`,
    `UTM campaign`,
    
    `Sessions total`,
	`Sessions desktop`,
 	`Sessions mobile`
FROM website_traffic_weekly
where `Week` >= '2015-03-02'
order by 1,4 desc;
--  Based on the weekly figures, the gsearch nonbrand campaign is contantly the top source of the traffic.
-- We can also see that in the gsearch nonbrand campaign, the traffic is unevenly distributed by device 
-- type with the desktop targeted generating the vast majorority of the incoming traffic. We can conclude that 
-- the gsearch nonbrand desktop targeted campaign should be in the center of our focus.
-- Regarding the session to order conversion rates (number of sessions where the user created an order), we 
-- can also see that there is a considerable difference based on the device type with an average 10% conversion 
-- rate in case of the desktop targeted and below 5% conversion rate in case of the mobile targeted campaign. 
-- On the 2015-03-16 week the gsearch brand desktop targeted campaign had the highest conversion rate with 10.7%.

-- Was socialbook a successful campaign in terms of the proportion of the bounced sessions (proportion of sessions where the user visited only one website page)?
SELECT 
	`Week`,
    `UTM source`,
    `UTM campaign`,
    
	`Orders total`,
	`Number of bounced user sessions`,
	`Bounce rate`
FROM website_traffic_weekly
where `UTM source` = 'socialbook';
-- According to the figues, socialbook was not an effective campaign as about 70% of the users landed on the website only visited one page.

-- Which were the top landing pages in 2014 and 2015?
SELECT *
FROM top_landing_pages;
-- In 2014 most users were landed on the /home page while in the first 3 months of 2015 more users were landed on the /lander-5.