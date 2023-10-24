# RFM Analysis for Customer Segmentation
You can interact with the dashboard in tableau public [here](https://public.tableau.com/views/customer_count_by_segments_dashboard/Dashboard1?:language=en-GB&publish=yes&:display_count=n&:origin=viz_share_link)
![Dashboard](https://github.com/PhilipSada/rfm-analysis-for-customer-segmentation/assets/55988995/a3eea32d-fe3a-4aa2-ba7c-7667782b6765)

## Project Overview
This project provides an RFM Analysis on a sales data sample which can be found on Kaggle. The RFM Analyis was done using SQL and the result was visualized with Tableau.

RFM Analysis is a data-driven marketing technique that stands for Recency, Frequency, and Monetary Value. It is used for customer segmentation based on their transaction behaviors.
- Recency (R): Measures how recently a customer made a purchase. Recent customers are often more engaged and likely to respond to promotions.
- Frequency (F): Indicates how often a customer makes a purchase. Frequent buyers indicate loyal customers who can be targeted for retention programs.
- Monetary Value (M): Represents the total amount spent by a customer. High spenders are valuable for revenue generation.


**Why RFM Analysis:**
RFM Analysis is used for customer segmentation because it provides a data-driven approach to understanding and categorizing customers based on their transaction behaviors: Recency, Frequency, and Monetary Value.
- Precision: RFM allows businesses to precisely categorize customers based on recent purchases, how often they buy, and how much they spend. This precision helps in creating highly targeted and effective marketing strategies.
- Identifying Customer Segments: By analyzing RFM scores, businesses can identify distinct customer segments such as high-value, loyal customers (high RFM scores) and infrequent, low-spending customers (low RFM scores). Each segment can then be treated differently based on their unique needs and behaviors.
- Personalization: RFM analysis enables businesses to personalize marketing messages and promotions. For instance, highly loyal customers might receive exclusive offers, while dormant customers might receive re-engagement incentives.
- Customer Lifecycle Management: RFM helps in understanding where customers are in their lifecycle. New customers can be nurtured differently from long-term, high-value customers, enhancing customer relationship management strategies.
- Retention and Upselling: RFM analysis identifies valuable customers who are likely to respond well to retention efforts. It also helps in identifying opportunities for upselling and cross-selling to increase customer spending.
- Resource Optimization: By focusing marketing efforts on segments that are most likely to respond, businesses can optimize their resources, ensuring that marketing budgets are efficiently allocated for maximum impact.

In summary, RFM analysis is a powerful tool for customer segmentation because it provides actionable insights, allowing businesses to tailor their marketing efforts, improve customer retention, and ultimately enhance overall customer satisfaction and revenue.

## Exploratory Data Analysis
Using SQL, an exploratory data analysis was conducted to understand the data before conducting the RFM Analysis.

```sql
---Inspecting Data
select * from[dbo].[sales_data_sample]

--checking unique values
select distinct STATUS from [dbo].[sales_data_sample]
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]
select distinct COUNTRY from [dbo].[sales_data_sample]
select distinct DEALSIZE from [dbo].[sales_data_sample]
select distinct TERRITORY from [dbo].[sales_data_sample]

---finding out if the company had full year operations in 2005
select distinct MONTH_ID from [dbo].[sales_data_sample]
where YEAR_ID = 2005

---Grouping sales by product line to find out which product line has the most sales and ordering it by the revenue in desc order
select PRODUCTLINE, sum(SALES) Revenue from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

---Finding the year the company made the most sales
select YEAR_ID, sum(SALES) Revenue from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

---Finding the deal size that has the most sales
select DEALSIZE, sum(SALES) Revenue from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc

----What was the best month for sales in a specific year? How much was earned that month?
select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency from [dbo].[sales_data_sample] 
where YEAR_ID = 2003
group by MONTH_ID
order by 2 desc

select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency from [dbo].[sales_data_sample] 
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc

--November seems to be the best month, what product do they sell in November.
select MONTH_ID, PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) Frequency from [dbo].[sales_data_sample] 
where YEAR_ID = 2004 and MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE --Month_ID and PRODUCTLINE are added here because they are not part of the aggregate functions
order by 3 desc
```

## RFM Analysis
An RFM Analysis was conducted in SQL to segment the customers of the business and by doing this, one could find the best customers.

```sql
DROP TABLE IF EXISTS #rfm --created temp. table so that the cte (Common Table Expression) is not called all the time

---using NTILE function to group records into 4 equal groups to make it easier to find patterns
--;With is used to define a CTE which is a temporary result set
;with rfm as 
(	select 
		CUSTOMERNAME, 
		sum(SALES) MonetaryValue, 
		avg(SALES) AvgMonetaryValue, 
		count(ORDERNUMBER) Frequency, 
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD,max(ORDERDATE),(select max(ORDERDATE) from [dbo].[sales_data_sample])) RecencyInDays
	from [dbo].[sales_data_sample] 
	group by CUSTOMERNAME
),
rfm_calc as (
	select r.*,
		NTILE(4) OVER (order by RecencyInDays) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	 from rfm r
)
select c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) +cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

--CUSTOMER SEGMENTATION

SELECT CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary,rfm_cell_string,
    case 
        when rfm_cell_string in (444,443,434,433) then 'churned best customer' --customers that have transacted a lot and frequent but it has been a long time since last transaction
        when rfm_cell_string in (421,422,423,424,434,432,433,431) then 'lost customer'
        when rfm_cell_string in (342,332,341,331) then 'declining customer'
        when rfm_cell_string in (344,343,334,333) then 'slipping best customer'--these are the best customer that have not purchased in a while
        when rfm_cell_string in (142,141,143,131,132,133,242,241,243,231,232,233) then 'active loyal customer' -- they have purchased recently, frequently, but have low monetary value
        when rfm_cell_string in (112,111,113,114,211,213,214,212) then 'new customer' 
        when rfm_cell_string in (144) then 'best customer'-- they have purchase recently and frequently, with high monetary value
        when rfm_cell_string in (411,412,413,414,313,312,314,311) then 'one time customer'
        when rfm_cell_string in (222,221,223,224) then 'Potential customer'
        else 'customer' -- average customer
    end rfm_segment


FROM #rfm

```
You can interact with the dashboard in tableau public [here](https://public.tableau.com/views/customer_count_by_segments_dashboard/Dashboard1?:language=en-GB&publish=yes&:display_count=n&:origin=viz_share_link)
![Dashboard](https://github.com/PhilipSada/rfm-analysis-for-customer-segmentation/assets/55988995/a3eea32d-fe3a-4aa2-ba7c-7667782b6765)

**One-Time Customers:**
Among the customers, 16 fall into the category of one-time buyers. To convert them into loyal patrons, personalized approaches are crucial. Offering exclusive discounts and engaging them through targeted marketing campaigns can remind them of their positive experience and encourage repeat business.

**Active Loyal Customers and Slipping Best Customers:**
Identifying 13 active loyal customers and 10 slipping best customers presents an opportunity for strengthening customer loyalty. Implementing a tiered loyalty rewards program for active customers ensures their continued patronage. Simultaneously, win-back campaigns can be initiated for slipping best customers, enticing them with special discounts and emphasizing the unique features of our offerings.

**Best Customers and Churned Best Customers:**
Nine best customers are the backbone of the business revenue stream. Focusing on maintaining their satisfaction is vital. Personalized services, early access to new products, and special loyalty events can further solidify their loyalty. For the five churned best customers, targeted re-engagement strategies can be employed, demonstrating the company's commitment to their satisfaction and urging them to return.

**New Customers and Potential Customers:**
The seven new customers signifies the company's expanding market reach. To cultivate their loyalty, personalized onboarding experiences and welcome offers can be provided. Additionally, the two potential customers represent untapped opportunities. Initiating direct outreach, offering tailored solutions, and highlighting our unique value proposition can convert potential into loyal patrons.

**Lost Customers**
Among the customer segments, five individuals fall into the category of lost customers. These are individuals who, for various reasons, have discontinued their engagement with the business. Understanding their departure is essential in devising effective strategies to win them back.
