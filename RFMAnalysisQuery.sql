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


--Analysis
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

----Who are the best customers (Using the RFM Analysis)
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

---Defining the kind of customers (A higher number in rfm_frequency and rfm_monetary means higher value but a higher number in rfm_recency means a lower value) 
/*select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary, 
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 421, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from  #rfm*/

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

-- Creating a new table with the customer segments
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
INTO customer_segmentation
FROM #rfm





---What products are most often sold together 
--An ordernumber could have mutliple rows which meanings that multiple items were purchased probably on the same day
--Using XML path to convert results to one column
--select * from [dbo].[sales_data_sample] where ORDERNUMBER = 10411
---using stuff to convert the result to a string (starting position = 1, number of characters to extract = 1, replace = '' (nothing))
---distinct is used since for each product code there was an ordernumber for it

select distinct ORDERNUMBER, stuff(
	(  
	  --Convert to XML Path
		select ',' + PRODUCTCODE
		from [dbo].[sales_data_sample] p
		where ORDERNUMBER in 
		(
		--This returns the order numbers that have 2 items
			select ORDERNUMBER
			from(
				--This returns the row numbers which could indicate the number of items in an order
				select ORDERNUMBER, count(*) rn --rn means row number
				from[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn =2
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')
	)
	,1,1,''
) ProductCodes
from [dbo].[sales_data_sample] s
order by 2 desc --to filter the data
