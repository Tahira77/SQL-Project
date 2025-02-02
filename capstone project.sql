use ecomm;

-- I) Data Cleaning:
/*			1a)Handling Missing Values and Outliers:

	➢ Impute mean for the following columns, and round off to the nearest integer if
required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,
DaySinceLastOrder.*/
set sql_safe_updates=0;
-- imputing mean value to the WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,DaySinceLastOrder columns

-- created a variables for each column and done the subquery, then assigned to it.
SET @ware_house_to_home=(select round(avg(WarehouseToHome)) from customer_churn);
Select @ware_house_to_home;

SET @Hour_Spend_On_App=(Select round(avg(HourSpendOnApp)) from customer_churn);
Select @Hour_Spend_On_App;

SET @Order_AmountHike_From_lastYear=(Select round(avg(OrderAmountHikeFromlastYear)) from customer_churn);
Select @Order_AmountHike_From_lastYear;

SET @Day_Since_Last_Order=(Select round(avg(DaySinceLastOrder)) from customer_churn);
Select @Day_Since_Last_Order;



-- imputed the mean to the columns
Update customer_churn 
SET warehouseToHome=@ware_house_to_home
Where warehouseToHome is null;

Update customer_churn 
SET HourSpendOnApp= @Hour_Spend_On_App
Where HourSpendOnApp is null;

Update customer_churn
SET OrderAmountHikeFromlastYear=@Order_AmountHike_From_lastYear
Where OrderAmountHikeFromlastYear is null;

Update customer_churn
SET DaySInceLastOrder=@Day_SInce_Last_Order
Where DaySInceLastOrder is null;

select * from customer_churn;

-- ➢ Impute mode for the following columns: Tenure, CouponUsed, OrderCount.

Select Tenure, count(*) from customer_churn group by Tenure;
Select CouponUsed, count(*) from customer_churn group by CouponUsed;
Select OrderCount, count(*) from customer_churn group by OrderCount;
-- there are 264 null in Tenure, 256 null in CouponUsed,  258 null values in OrderCount

SET @Tenure_mode=(Select Tenure from customer_churn 
group by Tenure 
Order by Count(*) Desc LIMIT 1);
Select @Tenure_mode;

SET @CouponUsed_mode=(Select CouponUsed from customer_churn 
group by CouponUsed
Order by count(*) Desc LIMIT 1);
Select @CouponUsed_mode;

SET @OrderCount_mode=(Select OrderCount from customer_churn 
group by OrderCount
Order by count(*) Desc LIMIT 1);
Select @OrderCount_mode;

-- imputed mode to the columns

Update customer_churn 
SET Tenure = @Tenure_mode
Where Tenure is null;

Update customer_churn 
SET CouponUsed = @CouponUsed_mode
Where CouponUsed is null;

Update customer_churn 
SET OrderCount = @OrderCount_mode
Where OrderCount is null;

select * from customer_churn;

-- ➢  Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.

DELETE from customer_churn
Where WarehouseToHome>100;

/*1 b) Dealing with Inconsistencies:

	➢Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and 
	“Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure
	uniformity. */
    
    Update customer_churn
    SET PreferredLoginDevice = IF(PreferredLoginDevice='Phone','Mobile Phone',PreferredLoginDevice);

/* ➢ Standardize payment mode values: Replace "COD" with "Cash on Delivery" and
"CC" with "Credit Card" in the PreferredPaymentMode column.*/
-- we use CASE, whenever there is multiple conditions.
	Update customer_churn
    SET PreferredPaymentMode= CASE
				When PreferredPaymentMode='COD' Then 'Cash on Delivery'
                When PreferredPaymentMode='CC' Then 'Credit Card'
                Else PreferredPaymentMode
			END;
select * from customer_churn;
/* II) Data Transformation:
		1. Column Renaming:
		➢ Rename the column "PreferedOrderCat" to "PreferredOrderCat".
           ➢ Rename the column "HourSpendOnApp" to "HoursSpentOnApp".*/
        Alter table customer_churn 
        RENAME Column PreferedOrderCat To PreferredOrderCat,
        RENAME Column HourSpendOnApp To HoursSpentOnApp;
        
        /* 2. Creating New Columns:
➢ Create a new column named ‘ComplaintReceived’ with values "Yes" if the
corresponding value in the ‘Complain’ is 1, and "No" otherwise.
➢ Create a new column named 'ChurnStatus'. Set its value to “Churned” if the
corresponding value in the 'Churn' column is 1, else assign “Active”.*/
-- column creation


ALTER table customer_churn
ADD Column ComplaintReceived enum('Yes','No'),
ADD column ChurnStatus enum('Churned','Active');
-- set values to the newly created columns
update customer_churn
SET ComplaintReceived= IF(complain=1,'Yes','No'),
	ChurnStatus=IF(Churn=1,'Churned','Active');
    
    -- Column Dropping:
-- ➢ Drop the columns "Churn" and "Complain" from the table.
Alter table customer_churn 
Drop column Churn,
Drop column Complain;

-- III)  Data Exploration and Analysis:
		-- 1. ➢ Retrieve the count of churned and active customers from the dataset.
        Select ChurnStatus, count(*) as Customer_status from customer_churn  
        group by ChurnStatus;
        
        -- 2. ➢ Display the average tenure and total cashback amount of customers who churned.
		Select round(Avg(Tenure)) As avg_tenure from customer_churn Where ChurnStatus='Churned';
        Select (sum(CashbackAmount)) As Total_Cashback from customer_churn Where CHurnStatus='Churned';
        
        -- 3. ➢ Determine the percentage of churned customers who complained.
	SELECT round((count(*) * 100.0) / (SELECT count(*) from customer_churn
    where ChurnStatus='Churned'),2) As percentage
    From customer_churn
    where churn_status='Churned' AND ComplaintReceived='Yes';
    
    -- 4. ➢ Find the gender distribution of customers who complained.
Select  Gender,count(*) as Count from customer_churn where ComplaintReceived = "Yes"
group by Gender;
  
  -- 5. Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.
Select CityTier,count(*) from customer_churn
where ChurnStatus='Churned' AND PreferredOrderCat='Laptop & Accessory'
order by ChurnStatus desc limit 1;

-- 6. ➢ Identify the most preferred payment mode among active customers.
Select PreferredPaymentMode,CHurnStatus,count(*) as preferrdPaymentMode_among_ActiveCustomer from customer_churn
where ChurnStatus='Active'
group by PreferredPaymentMode
order by preferrdPaymentMode_among_ActiveCustomer desc limit 1;

-- 7. ➢ Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
Select Sum(OrderAmountHikeFromlastYear) as Total_Order_Amount_Hike_From_Lastyear,PreferredOrderCat from customer_churn 
where MaritalStatus = "Single" and PreferredOrderCat ="Mobile Phone";

-- 8. Find the average number of devices registered among customers who used UPI as their preferred payment mode.
Select round(Avg(NumberOfDeviceRegistered))As avg_device_registered,PreferredPaymentMode from customer_churn
where PreferredPaymentMode='UPI';

-- 9. Determine the city tier with the highest number of customers.
Select CityTier,count(*) as customer_count from customer_churn
group by CityTier
order by customer_count Desc Limit 1;

-- 10.Identify the gender that utilized the highest number of coupons.
Select gender,sum(CouponUsed) As highest_no_of_coupon
from customer_churn
group by gender
order by highest_no_of_coupon desc Limit 1;

-- 11. List the number of customers and the maximum hours spent on the app in each preferred order category.
Select count(*) as customer_count,PreferredOrderCat, max(HoursSpentOnApp) as maximum_hours_spent
from customer_churn
group by PreferredOrderCat;

-- 12.Calculate the total order count for customers who prefer using credit cards and
-- have the maximum satisfaction score.

select Sum(OrderCount),PreferredPaymentMode,SatisfactionScore from Customer_Churn
Where PreferredPaymentMode = "Credit card" 
Group By SatisfactionScore order by SatisfactionScore desc limit 1 ;

-- 13.How many customers are there who spent only one hour on the app and days
-- since their last order was more than 5?

Select count(*) as customer_count from customer_churn
where HoursSpentOnApp=1 AND DaySinceLastOrder > 5 ;

-- 14.What is the average satisfaction score of customers who have complained?
Select ComplaintReceived,Round(avg(SatisfactionScore)) as avg_satisfaction_score 
from customer_churn
where ComplaintReceived='Yes';

-- 15.List the preferred order category among customers who used more than 5 coupons.
Select PreferredOrderCat,COUNT(*) AS CustomerCount from customer_churn
where CouponUsed>5
group by PreferredOrderCat
Order by CustomerCount DESC LIMIT 1;

-- 16.List the top 3 preferred order categories with the highest average cashback amount.
Select PreferredOrderCat,round(avg(CashbackAmount)) as average_cashbackAmount from customer_churn
group by PreferredOrderCat
order by average_cashbackAmount
Desc Limit 3;

-- 17. Find the preferred payment modes of customers whose average tenure is 10
-- months and have placed more than 500 orders.
Select Count(orderCount) as OrderCounts,round(Avg(Tenure)) as Average_tenure,PreferredPaymentMode from customer_churn
Group By PreferredPaymentMode Having (OrderCounts>500 and Average_tenure =10) ;

-- 18
/*Categorize customers based on their distance from the warehouse to home such
as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,
'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the
churn status breakdown for each distance category.*/

Select ChurnStatus, WarehouseToHome,
Case
when WareHouseToHome <= 5 Then "Very Close Distance"
when WareHouseToHome <= 10 Then "Close Distance"
When WareHouseToHome <= 15 Then "Moderate Distance"
Else "Far Distance"
End as WareHouseToHomeDetails
from Customer_churn;
    
    -- 19. List the customer’s order details who are married, live in City Tier-1, and their
-- order counts are more than the average number of orders placed by all customers.
        
        Select * from customer_churn
        where MaritalStatus='Married'
        AND CityTier=1 AND OrderCount>(select avg(OrderCount) from customer_churn);
        
        -- 20.➢ a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:
      CREATE TABLE  customer_returns(
      ReturnID INT primary key,
      CustomerID INT not null,
      ReturnDate DATE not null,
      RefundAmount Decimal(10,2) not null
      );
      
      INSERT INTO customer_returns(ReturnID,CustomerID,ReturnDate,RefundAmount)
      VALUES(1001, 50022, '2023-01-01', 2130),
    (1002, 50316, '2023-01-23', 2000),
    (1003, 51099, '2023-02-14', 2290),
    (1004, 52321, '2023-03-08', 2510),
    (1005, 52928, '2023-03-20', 3000),
    (1006, 53749, '2023-04-17', 1740),
    (1007, 54206, '2023-04-21', 3250),
    (1008, 54838, '2023-04-30', 1990);
    
-- 21.Display the return details along with the customer details of those who have churned and have made complaints.
  
  Select r.ReturnID,r.CustomerID,r.ReturnDate,r.RefundAmount,c.ComplaintReceived,c.ChurnStatus,c.CustomerID
   from customer_returns r
   join customer_churn c ON r.CustomerID=c.CustomerID 
   Where c.ChurnStatus='Churned' AND c.ComplaintReceived='yes';
   
   
   Select * from customer_Returns;
select * from customer_churn;