use sqlprojects;

select * from dbo.credit_card_transcations$;

select min(transaction_date), MAX(transaction_date) from dbo.credit_card_transcations$;

select distinct exp_type from dbo.credit_card_transcations$;

--1-Write a query to print top 5 cities with the highest spends
--and their percentage contribution of total credit card spends

with cte as (
select city, sum(amount) as total_spend 
from dbo.credit_card_transcations$ 
group by city)
,total_spent as (select sum(cast(amount as bigint)) as total_amount from dbo.credit_card_transcations$)
select top 5 cte.*, round(total_spend/total_amount * 100,2)as percentage_contribution 
from cte, total_spent 
order by cte.total_spend desc;

--2-Write a query to print highest spend month and amount spent in that month for each card type

with cte as (select card_type, datepart(year,transaction_date) as yt, datepart(month,transaction_date) as mt, sum(amount) as total
from dbo.credit_card_transcations$
group by card_type, datepart(year,transaction_date), datepart(month,transaction_date)
)
,cte2 as(select *, rank() over(partition by card_type order by total desc) as rn from cte)
select * from cte2 where rn=1; 

--3-Write a query to print the transactions details (all columns from table) for each card type 
--when it reaches a cumulative of 1000000 of total spends.

with cte as (select *, sum(amount) over(partition by card_type order by transaction_date, transaction_id) as cs
from credit_card_transcations$)
select card_type, cs from (select *,RANK() over(partition by card_type order by cs) as rk from cte where cs >= 1000000) a where rk=1
union
select card_type, cs from (select *, sum(amount) over(partition by card_type order by transaction_date, transaction_id) as cs
from credit_card_transcations$) b where cs<1000000 order by card_type;

--4-Write a query to find the city with the lowest percentage of the gold card type.
with cte as (
select city, card_type, sum(amount) as amount,sum(case when card_type = 'Gold' then amount end)as gold_amount from credit_card_transcations$ 
group by city, card_type
)
select top 1
city, sum(gold_amount)/sum(amount) as ratio from cte 
group by city 
having sum(gold_amount) is not null
order by ratio;

--5-Write a query to print the city, highest_expense_type, lowest_expense_type.

with cte as (
select city, exp_type, sum(amount) as total, rank() over(partition by city order by sum(amount) desc) as rn
from credit_card_transcations$ group by city, exp_type
)
,cte2 as(
select city, exp_type, sum(amount) as total, rank() over(partition by city order by sum(amount)) as rn
from credit_card_transcations$ group by city, exp_type
)
select cte.city, cte.exp_type as Highest_exp_type, cte2.exp_type as Lowest_exp_type from cte join cte2 on cte.city = cte2.city
where cte.rn=1 and cte2.rn=1;

--6-Write a query to find percentage contribution of spends by females for each expense types

select exp_type, 
sum(case when gender = 'F' then amount else 0 end)/sum(amount) * 100 as percentage_contribution_by_female
from credit_card_transcations$  
group by exp_type;

--7-Write a query to find that which card and expense type combination saw highest month over month growth in jan-2014

with cte as (
select card_type, exp_type, DATEPART(YEAR,transaction_date) as yt, DATEPART(month,transaction_date) as mt, sum(amount) as Amount
from credit_card_transcations$ 
group by card_type, exp_type, DATEPART(YEAR,transaction_date), DATEPART(month,transaction_date))
select top 1 *, (Amount - prevamount) as momgrowth from
(select *, lag(Amount,1) over(partition by card_type,exp_type order by yt, mt) as prevamount from cte) a 
where prevamount is not null and yt = '2014' and mt = '1'
order by momgrowth desc;

--8-Write a query to find that during weekends which city has highest total spend to total no of transactions ratio

select top 1 city, sum(amount) / count(1) as ratio
from credit_card_transcations$
where  DATEPART(WEEKDAY,transaction_date) in (1,7)
group by city
order by ratio desc;

--9-Write a query to find that which city took least number of days to reach its 
-- 500th transaction after the first transaction in that city

with cte as (
select *
, ROW_NUMBER() over(partition by city order by transaction_date) as rn
from credit_card_transcations$)
select top 1 city, datediff(day,min(transaction_date), max(transaction_date)) as datediff1
from cte
where rn = 1 or rn = 500
group by city
having count(*) = 2
order by datediff1


select transaction_id from credit_card_transcations$