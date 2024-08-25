-- Question Set: Easy
-- 1. Who is the senior most employee based on job title?

Select*From employee
Order by levels desc
limit 1;

-- 2. Which countries have the most Invoices?

Select count(*) as most_invoices, billing_country From invoice
group by billing_country
Order by most_invoices Desc
Limit 1;

-- 3. What are top 3 values of total invoice?

Select total from invoice
Order by total desc
Limit 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

Select sum(total) as total_invoice_count, billing_city From invoice
Group by billing_city
order by total_invoice_count desc
limit 1;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money

Select t1.customer_id, t1.first_name, t1.last_name, sum(t2.total) as total_amount_spent From customer as T1
Join
invoice as T2 on t1.customer_id=t2.customer_id
group by t1.customer_id
Order by total_amount_spent Desc
Limit 1;

-- Question Set: Moderate

-- 1. Write query to return the email, first name, last name, & genre of all Rock Music listeners. 
--    Return your list ordered alphabetically by email starting with A

Select distinct(t1.customer_id), t1.first_name, t1.last_name, t1.email, t5.name From customer as T1
Join
invoice as T2 on t1.customer_id=t2.customer_id
Join
invoice_line as T3 on t3.invoice_id=t2.invoice_id
Join
track as T4 on T4.track_id = t3.track_id
Join
genre as t5 on t5.genre_id = t4.genre_id
where t5.name = 'Rock'
order by t1.email Asc;

-- Optimized Query

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

-- 2. Write a query that returns the Artist name and total track count of the top 10 rock bands

Select
	T1.name, Count(T1.artist_id) as Track_Count

From
artist as T1

Join
album as T2 On T1.artist_id = T2.artist_id
Join
track as T3 On T3.album_id = T2.album_id
Join
genre as T4 On T4.genre_id = T3.genre_id

Where T4.name Like 'Rock'
Group By T1.name
Order By Track_Count Desc
Limit 10;

-- 3. Return all the track names that have a song length longer than the average song length. 
--    Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first

Select name, milliseconds 
from track
where milliseconds> (Select AVG(milliseconds) as average from track)
Order by milliseconds Desc;

-- Question Set: Advance

-- 1. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent

Select T1.customer_id, T1.first_name,T1.last_name, T6.name, Sum(T3.unit_price*T3.quantity) 

From customer as T1

Join
invoice as T2 On T1.customer_id = T2.customer_id

Join
invoice_line as T3 on T3.invoice_id = T2.invoice_id

Join
track as T4 on T4.track_id = T3.track_id

Join
album as T5 on T5.album_id = T4.album_id

Join
artist as T6 on T6.artist_id = T5.artist_id

Group by 1,2,3,4
Order by 4 Asc, 5 Desc;

-- Checking for only best selling artist using CTE

with best_selling_artist as (
Select A.artist_id, A.name, Sum(Il.unit_price*Il.quantity) from artist as A
Join 
Album as Al on A.artist_id = Al.artist_id
Join
Track as T on Al.album_id = T.album_id
Join
Invoice_line as Il on T.track_id = Il.track_id
Group by 1,2
Order by 3 Desc
Limit 1
)
Select T1.customer_id, T1.first_name,T1.last_name, T6.name, Sum(T3.unit_price*T3.quantity) as Total_Sale

From customer as T1

Join
invoice as T2 On T1.customer_id = T2.customer_id
Join
invoice_line as T3 on T3.invoice_id = T2.invoice_id
Join
track as T4 on T4.track_id = T3.track_id
Join
album as T5 on T5.album_id = T4.album_id
Join
best_selling_artist as T6 on T6.artist_id = T5.artist_id

Group By 1,2,3,4
Order By 4 Asc, 5 Desc;

-- 2. We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases. 
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres

With Recursive
find_purchase_count as
	(
		Select count(*) as purchase_count, c.country, g.name, g.genre_id
		From invoice_line as il
		Join invoice as i On i.invoice_id = il.invoice_id
		Join customer as c On c.customer_id = i.customer_id
		Join track as t On t.track_id = il.track_id
		Join genre as g On g.genre_id = t.genre_id
		Group By 2,3,4
		Order by 2
	),
max_purchase_count as
	(
	Select Max(purchase_count) as M_purchase_count,country
	from find_purchase_count
	Group by 2
	Order by 2
	)
Select pc.* From
find_purchase_count as pc
Join max_purchase_count as mpc On pc.country = mpc.country
Where pc.purchase_count = mpc.M_purchase_count
Order By purchase_count Desc;

-- Alternate Method with CTE

With max_purchase_count As
	(
		Select count(*) as purchase_count, c.country, g.name, g.genre_id,
		Row_Number() Over(Partition By (c.country) Order By Count(il.quantity) Desc) As RowNo
		From invoice_line as il
		Join invoice as i On i.invoice_id = il.invoice_id
		Join customer as c On c.customer_id = i.customer_id
		Join track as t On t.track_id = il.track_id
		Join genre as g On g.genre_id = t.genre_id
		Group By 2,3,4
		Order by 2
	)
	Select purchase_count, country, name, genre_id 
	From max_purchase_count
	Where RowNo=1
	Order By purchase_count Desc;

-- 3. Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount

With Recursive
customer_spending as
	(
		Select c.customer_id, c.first_name, c.last_name, i.billing_country, Sum(i.total) as amount_spent
		From invoice as i
		Join customer as c On c.customer_id = i.customer_id
		Group By 1,2,3,4
		Order by 1, 5 Desc
	),

max_amount_spent as
	(
	Select Max(amount_spent) as M_amount_spent, billing_country
	from customer_spending
	Group by 2
	Order by 2
	)

Select cs.* From
customer_spending as cs
Join max_amount_spent as mas On cs.billing_country = mas.billing_country
Where cs.amount_spent = mas.M_amount_spent
Order By 5 Desc;

-- Alternate Method with CTE

With max_amount_spent As
	(
		Select c.customer_id, c.first_name, c.last_name, i.billing_country, Sum(i.total) as amount_spent,
		Row_Number() Over(Partition By (i.billing_country) Order By Sum(i.total) Desc) As RowNo
		From invoice as i
		Join customer as c On c.customer_id = i.customer_id
		Group By 1,2,3,4
		Order by 1, 5 Desc
	)
	Select customer_id, first_name, last_name, billing_country, amount_spent From max_amount_spent
	Where RowNo=1
	Order By amount_spent Desc;
