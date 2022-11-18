# Advanced SQL

There are many cases with SQL where basic syntax is not enough to achieve what you want. Luckily for us, SQL rich syntax beyond the basics to fulfill all the requirements regarding data extraction.

In this chapter I'm going to cover more SQL topics and techniques.

Here is a brief plan:
- first I'll cover subqueries, common table expressions and unions
- next, how to create tables and put some data inside
- joins between tables
- lastly, I'll touch window functions

Many of such topics should be a separate chapters by themselves. However, I'll try to give a sensible definition and examples for you to get started. With practice you will discover more use-cases and possible syntax for all the cases.

Let's get started!

# The example data

In this chapter you will continue to work with [sample data]() I generated for the [beginner chapter](). Let's do a quick recap.

You have two tables in the database.

`Users` table contains info about people registered on your imaginary online store:
```
id |first_name |last_name |email                          |reg_date           |country             
---+-----------+----------+-------------------------------+-------------------+--------------------
  1|Danielle   |Johnson   |danielle.johnson88@gmail.com   |2018-04-08 03:47:32|Burundi             
  2|Jill       |          |jill.rhodes07@gmail.com        |2019-12-16 12:45:52|Antigua and Barbuda 
  3|Anthony    |Robinson  |anthony.robinson04@hotmail.com |2016-08-05 02:39:30|Moldova             
  4|James      |Santos    |james.santos07@yahoo.com       |2018-03-30 13:14:13|Kiribati            
  5|Bridget    |Pacheco   |bridget.pacheco70@gmail.com    |2019-12-18 16:24:24|Guam                
  6|Joshua     |Lewis     |joshua.lewis92@gmail.com       |2017-02-26 19:37:28|Hong Kong           
  7|Colin      |Abbott    |colin.abbott11@yahoo.com       |2016-09-26 15:53:33|Saint Lucia         
```

`Payments` table contains purchases your users made:
```
id |event_date         |gross_revenue|currency|user_id|tax_rate
---+-------------------+-------------+--------+-------+--------
  1|2021-02-01 11:04:21|        99.99|EUR     |    861|    0.18
  2|2018-11-04 02:14:12|        99.99|EUR     |   5735|    0.32
  3|2018-06-22 23:58:55|        99.99|USD     |   4427|    0.18
  4|2019-07-16 09:20:59|        29.99|EUR     |   8323|    0.32
  5|2019-05-30 13:44:37|        29.99|EUR     |   6950|    0.32
  6|2019-04-26 21:24:47|        29.99|USD     |   4556|    0.32
  7|2018-12-17 21:51:52|        59.99|USD     |   8667|    0.18

```

In all my examples I'll refer to these two tables.

For convenience of testing your scripts you can use online service [sqlime.org](https://sqlime.org/). To connect our sample data set you need to [download](https://github.com/oleg-agapov/data-engineering-book/raw/master/book/2-beginner-path/2-2-sql-for-beginners/assets/db.sqlite) it first and then upload to sqlime with "open file" button.

# Subqueries

The very first enhancement of existing SQL syntax is subqueries.

**Subquery is an SQL query nested inside another query**.

Subqueries can be used in different parts of your query (SELECT, FROM, WHERE, UPDATE statements).

Usually subqueries are used in cases when you need to combine results from two or more tables. (However, table joins might be a better alternative, but we will discuss joins a bit later)

**Example 1**. Let's suppose you want to get a table wich will show a list of your users with their first and last names along with their total spendings.

To solve that you need to use both tables: `users` and `payments`. The final query may look like this:

```sql
SELECT
	first_name,
	last_name,
	(SELECT
        sum(gross_revenue)
    FROM payments p
    WHERE p.user_id = u.id) AS total_spendings
FROM users u
```

The result will be:
```
first_name |last_name  |total_spendings
-----------+-----------+---------------
Danielle   |Johnson    |               
Chad       |Stanley    |          99.99
John       |Tran       |          59.99
...
```

This is a subquery in SELECT. Such subquery will be calculated for **each row** in the original dataset. It means that the subquery was evaluated as many times, as the number of records in the `users` table in my example.

To make it work follow these simple rules:
- return only one row and one column, otherwise you'll get an error
- use filtering conditions, e.g. for each row I passed user_id from outer table inside the subquery

Be aware that this may cause some performance issues with big tables, so test your solution before running on production databases.

**Example 2**. Calculate a distribution of customers by the number of purchases they made. For example:
- 90 customers made only one purchase
- 42 customets made exactly two purchases
- and so on

To solve such case you need two steps:
1. calculate how many purchases made each of your customer
2. based on the first step calculate the distribution

You can do that with nested query, like this:
```sql
SELECT
	purchases,
	count(user_id) AS customers
FROM (SELECT
		user_id,
		count(1) AS purchases
	  FROM payments p
	  GROUP BY user_id)
GROUP BY purchases
ORDER BY customers DESC
```

In this example you see one query wrapped around another query. And such pattern you will see very often.


**Example 3**. Get a list of purchases from the customer with the first name "John".

Again, let's deconstruct the requirement into two parts:
1. first let's extract all purchases
2. limit those purchases only to users with the name John

Here is how you can solve it with subquery:
```sql
SELECT
	*
FROM payments p
WHERE p.user_id IN (
	SELECT u.id
	FROM users u
	WHERE u.first_name = 'John'
)
```

This is an example of subquery in WHERE. Outer query selects all data from `payments` table, while subquery limits it to only users with the name John.

Pay attention, that such subquery returns only one column but multiple rows (unlike a subquery in SELECT which _have_ to return a single value).

## Short summary

As you can see, subqueries is a good way to combine two datasets into a single query. You can come up with some very clever ways of representing your data using subqueries. No worries if they seem to complicated right now, you'll get use to them very quickly once they click inside your brain.

# Common Table Expressions (CTE)

Common Table Expressions is a nice way to make your query more readable and understandable by splitting it into smaller tables. This is how you can create CTEs:

```sql
WITH <table_expression_name> AS (
    <query_definition>
)
[, <another_table_expression_name> AS (..)]

SELECT * 
FROM <table_expression_name>
```

Here is how it works:
- at the top you write a WITH keyword which means that you want to define a new (temporary) table
- next you write its desired name (alias), it can be any arbitrary name (you will use later)
- then you define a table as SELECT expression
- you can have as many tables as you need, it can be one, can be many
- finally, you write a usual SELECT statement and can refer to your newly created table expression(s)

Let's look at the example. Easiest way to illustrate that is to recall an earlier example with orders distribution.

**Example 4**. Calculate a distribution of customers by the number of purchases they made using Common Table Expressions.

If you remember correctly previous example, we used subquery in FROM to solve the task, but it can be easily refactored to CTE:

```sql
WITH table_purchases AS (
    SELECT
	    user_id,
		count(1) AS purchases
	FROM payments p
	GROUP BY user_id
)

SELECT
	purchases,
	count(user_id) AS customers
FROM table_purchases
GROUP BY purchases
ORDER BY customers DESC
```

Now you have two distinct parts of your query:
- inside the `table_purchases` expression you are calculating a number of purchases per user
- and in the outer SELECT you refer that table expression for the further calculations

Such code is a bit easier to read and it gives you more understanding of what is going on inside it.


# Views

Many databases support **views**. In simple words, view is a virtual table that does not store data by itself, but is constructed using SQL query.

Views work in the following way:
1. you create an SELECT query that return you some result-set
2. using that query you can create a virtual table (or view) that can represent that result-set
3. next time you would like to use such data, you call your view instead of writing that SQL again

Consider the following example.

**Example 5**. Each month your company should pay taxes, so your task is to calculate the amount you should pay.

Let's recall our `payments` tables once again:

```
id |event_date         |gross_revenue|currency|user_id|tax_rate
---+-------------------+-------------+--------+-------+--------
  1|2021-02-01 11:04:21|        99.99|EUR     |    861|    0.18
  2|2018-11-04 02:14:12|        99.99|EUR     |   5735|    0.32
  3|2018-06-22 23:58:55|        99.99|USD     |   4427|    0.18
  4|2019-07-16 09:20:59|        29.99|EUR     |   8323|    0.32
  5|2019-05-30 13:44:37|        29.99|EUR     |   6950|    0.32
  6|2019-04-26 21:24:47|        29.99|USD     |   4556|    0.32
```

Here we have order data, gross amount and tax rate. This information is enough to produce the desired result:

```sql
SELECT
	strftime('%Y-%m', event_date) AS report_month,
	round(sum(gross_revenue * tax_rate), 2) AS tax_amount
FROM payments
GROUP BY 1
ORDER BY 1
```

Such query will produce:

```
report_month|tax_amount
------------+----------
2018-05     |    234.16
2018-06     |    453.14
2018-07     |    319.35
2018-08     |     591.3
2018-09     |    434.93
2018-10     |    560.92
2018-11     |    431.34
```

From here we have two options:
1. to save the SQL and recall it each time you need to calculate taxes
2. create a view out of it and call that view instead

I'll go with the second scenario.

Creating a view is very simple, check out the code:

```sql
CREATE VIEW tax_view AS
SELECT
	strftime('%Y-%m', event_date) AS report_month,
	round(sum(gross_revenue * tax_rate), 2) AS tax_amount
FROM payments
GROUP BY 1
ORDER BY 1 
```

Here I declare `CREATE VIEW` statement and give it an alias `tax_view`. After that you put the desired SQL. 

To use this view you just call as usual table, like this:

```sql
SELECT * FROM tax_view
```

And voila! You have the same result as using the SELECT statement, but now you don't have to remember the query itself.

No data is stored for this view, it is merely a reflection of the existing `payments` table.

However, some databases may give you so called **materialized views**. Basically it is a view that creates a physical copy of the resulting set.

# Unions

**Union** is a way to combine two or more results of SELECT statement into a single table that contains rows from all the tables in the union.

In order to be successful, there are a couple of rules that your tables should satisfy:
1. every table should have the same number of columns
2. order of the columns should be the same
3. data types of the columns should be the same

This may sound like a lot of restrictions, but in practice these rules are just a common sense.

To illustrate how UNION work I'll bring a bit of artificial example, yet you may stop it in the real environment.

Consider that you have two different tables with orders:
1. `orders_2020` with orders for 2020
2. `orders_2021` for 2021

Now imagine that you need to analyse orders from both years at the same time. How can you do it with a single query?

With UNION operator it's easy:

```sql
SELECT * FROM orders_2020

UNION

SELECT * FROM orders_2022
```

Here I make an assumption that both tables have the same columns with the same data types.

Let's rewrite this example using our `payments` table to simulate this case on a real data:

```sql
SELECT
	event_date,
	gross_revenue ,
	currency,
	user_id
FROM payments
WHERE event_date BETWEEN '2020-01-01' AND '2020-12-31 23:59:59'

UNION

SELECT
	event_date,
	gross_revenue ,
	currency,
	user_id
FROM payments
WHERE event_date BETWEEN '2021-01-01' AND '2021-12-31 23:59:59'
```

> ***Question*. Can you change the query above so that it is using CTEs?

After executing the query you'll get a result-set that contains rows from both tables for 2020 and 2021.

You could try to break this example by adding or removing a column from any queries above or below the UNION. You'll get an error like:

```
SELECTs to the left and right of UNION do not have the same number of result columns
```

which means that the database cannot perform the union because it can't find matching column in the upper or lower query.

Another thing to mention is that *UNION operator will exclude duplicated rows*. So if identical row is present in the lower query it won't be placed in the result-set two times. If for some reason you need to include all rows from both queries you can use `UNION ALL` operator.

Unions can be chained like this:

```sql
SELECT * FROM table_1

UNION

SELECT * FROM table_2

UNION

SELECT * FROM table_3

-- and so on
```

# Joins

Joins is a topic that deserves a separate chapter in this book. Yet, I'll try to explain as easy as possible so that you can pick-up joins and master them with time and additional learning.

**Joins** are special operators (clauses) that allow you to combine two tables together based on their relation. Unlike subqueries or unions, joins are much often used in situation where two tables need to be presented in a single result-set.

Joins are always done with two tables, usually referred as *left* and *right* tables. One SQL query can contain one, many or none joins.

Joins are usually done by some common column(s). Such columns are usually called relations, thus the name of databases includes word "relational".

Operation of join is better explained on examples. So let's dive in.

## JOIN statement

**Example 6**. Finance team wants to know the breakdown of orders and gross revenue per country and ask you to calculate this per year. The resulting table should have the following format:

```
report_year|country|orders|gross_revenue
-----------+-------+------+-------------
        ...|    ...|   ...|          ...
```

First of all, let's analyze the resulting columns and try to figure out their sources:
- *report_year*, *orders* and *gross_revenue* clearly should come from `payments` table
- however *country* column is present in `users` table only

Ok, we figured out sources. But how payments and users are connected (related) with each other? They are connected through `user_id` field. That is our common column that is going to be used in a join.

Let's make a simplest join of two tables and see how the resulting table look like:

```sql
SELECT *
FROM payments
JOIN users ON users.id = payments.user_id
```

Basic syntax of JOIN statement is following:
- JOIN should come right after the FROM statement
- next we put a name of the table we want to join
- finally, after ON statement we put a condition of join, e.g. the columns (keys) that relates to each other from two tables
- pay attention, because keys are comins from different tables it is a good practice to user table names (or aliases) in front of the column name

Result of the query will look like this:

```
id |event_date         |gross_revenue| ...|id  |first_name | ...
---+-------------------+-------------+----+----+-----------+----
  1|2021-02-01 11:04:21|        99.99| ...| 861|Cheryl     | ...
  2|2018-11-04 02:14:12|        99.99| ...|5735|Christian  | ...
  3|2018-06-22 23:58:55|        99.99| ...|4427|Albert     | ...
  4|2019-07-16 09:20:59|        29.99| ...|8323|Jared      | ...
  5|2019-05-30 13:44:37|        29.99| ...|6950|Christopher| ...
  6|2019-04-26 21:24:47|        29.99| ...|4556|Lisa       | ...
  7|2018-12-17 21:51:52|        59.99| ...|8667|Joseph     | ...
```

I'm skipping some of the columns because they won't fit on the screen. But the result behind the join should be visible: for any row in the `payments` table we matched a row from `users` table using `user_id` as a matching key.

From this point you can use such joined result-set as a basis for any further calculations (selecting columns, aggregations, grouping, etc).

Here a solution to the initial task using a join:

```sql
SELECT
	strftime('%Y', payments.event_date) AS report_year,
	users.country,
	count(payments.id) AS orders,
	sum(payments.gross_revenue) AS gross_revenue
FROM payments
JOIN users ON users.id = payments.user_id
GROUP BY 1, 2
ORDER BY 1, 2
```

Let's go through this query step-by-step to figure out what is going on:
1. Our "main" table is `payments`, so we select all rows from it (look at FROM statement)
2. Next we do a join of `users` table by user's ID (`users.id = payments.user_id`)
3. When two tables are combined, we have access to columns from both, so we could create a grouping and aggregation expressions

This type of join is sometimes called an "inner join" because the resulting table will only **contain the rows that are present in both tables**. In some databases you may even see a special syntax, like this:

```sql
...
FROM table_1
INNER JOIN table_2 ON ...
```

Such behavior is not always needed. Sometimes you still want rows from one table even if there is no match in the other table. To handle such cases there are other types of joins: LEFT JOIN and RIGHT JOIN.

## LEFT JOIN

**Example 7**. Create a table of all users in your database and their lifetime spendings. If a user doesn't have spendings, leave this column empty.

This task is abosulutely identical to example 1, but here let's use a join instead of a subquery.

Let's figure out steps we need to perform in this task:
1. Because we need every user from our database let's take `users` table as a main table
2. For those users who have orders we could join their transactions from the `payments` table

One problem here is that if we join `payments` table to `users`, we will loose those users who have no orders (because users with no transactions won't match any user in `payments`). Luckily we are not limited to inner join and could use LEFT join here. Here is a solution:

```sql
SELECT
	first_name,
	last_name,
	sum(gross_revenue) AS total_spendings
FROM users
LEFT JOIN payments ON payments.user_id = users.id
GROUP BY first_name, last_name
ORDER BY total_spendings DESC
```

So, LEFT JOIN works like that: 
- for rows where keys fron both tables matched you will see the joined data
- if no rows were matched from the joined table you will see NULLs for such rows
- no rows will be excluded from the main table, only new data will be attached to the matched keys

RIGHT JOIN will work in a different way: it will leave all the rows from the joined table and exclude rows from the main table.

## Duplication of rows

**What will happen if joined table has more then one row to match with the main table**? In such case JOIN (inner or left) will duplicate rows in the original table to have the same number of rows as in the joined table. It's better seen on the example.

Suppose we have one user in our database:

```
user_id | first_name
--------+------------
      1 | John      
```

And this user made two purchases:

```
order_id | gross_revenue|user_id 
---------+--------------+--------
       1 |        29.99 |      1 
       2 |        49.99 |	   1 
```

Now let's try to join them (I will use a bit of CTE and UNION magic to create those two tables):

```sql
WITH table_users AS (
SELECT
	1 AS user_id,
	'John' AS first_name
)
,
table_orders AS (
SELECT
	1 AS order_id,
	29.99 AS gross_revenue,
	1 AS user_id
UNION
SELECT
	2 AS order_id,
	49.99 AS gross_revenue,
	1 AS user_id
)

SELECT *
FROM table_users
JOIN table_orders ON table_orders.user_id = table_users.user_id
```

You will get:

```
user_id|first_name|order_id|gross_revenue|user_id
-------+----------+--------+-------------+-------
      1|John      |       1|        29.99|      1
      1|John      |       2|        49.99|      1
```

Can you see what is happening here? User's row was duplicated as many times as many matches were in the joined table. Pay attention to this fact in the future.


## Cross join

Cross join is a type of join where every row from the left table is matched with every row from the right table. This join type is also known as Cartesian product.

As use probably guessed, cross join does not require from you to give it a key, because it will match every row with every row anyway. However, you still can do some filtering in the WHERE statement afterwards.

To illustrate how cross join works I'll give you one short example. Suppose we have two tables with:

```
col1|
----+
   1|
   2|
   3|
```

and 

```
col2|
----+
bar |
baz |
foo |
```

To produce cross join of these tables you just need to write both of them in FROM statement separated by comma:

```sql
SELECT *
FROM table_1, table_2
```

The output will look like this:

```
col1|col2
----+----
   1|bar 
   1|baz 
   1|foo 
   2|bar 
   2|baz 
   2|foo 
   3|bar 
   3|baz 
   3|foo 
```

Do you see what is happening here? Every row from the first table was joined with every row of the second table.

To illustrate the need of cross joins I'll show you a real-life application of this join. The example might be a bit hard to understand at the first sight, so don't worry if you can catch it first time. Practive will make it easiers :)

**Example 8***. Prepare a dataset that reports a rolling amount of gross revenue monthly. Monthly rolling amount means that you need to sum up the amount from the current month with the amount for all the past months.

Let's brake this example into smaller steps:
1. We need to calculate the amount of gross revenue for each month
2. To create a rolling metric we need to follow the algorithm:
	- for the very first month in order, the rolling metric equals to the amount in that 1st month
	- for the second month, rolling metric = amount for the 2nd month + amount for the 1st month
	- for the third month, rolling metric = amount for the 3rd month + amount for months (1, 2)
	- and so on...

To solve the first point you need to apply simple aggregation, we've done that many times in this chapter. The second point however brings an interesting challenge – you have a recursion there, which means that next row will depend on the previous in order. Such recursions are easily solved with cross joins of the table with itself.

Here is a full solution:

```sql
WITH table_monthly_sales AS (
	SELECT
		strftime('%Y-%m', event_date) AS report_month,
		sum(gross_revenue) AS gross_revenue
	FROM payments
	GROUP BY 1
)
SELECT
	t1.report_month,
	t1.gross_revenue,
	sum(t2.gross_revenue) AS rolling_gross_revenue
FROM table_monthly_sales t1, table_monthly_sales t2
WHERE t2.report_month <= t1.report_month
GROUP BY 1, 2
```

Take your time and try to figure out what is going on here.

## Closing thoughts about joins

Joins is a powerful way to combine data from multiple tables and extract more data in a single run. By joining tables you get richer results gaining extra knowledge about your data.

- Use joins whenever you need to combine data from two or more tables in a single query
- Use joins when you want to make an aggregation in one table but grouped by a column in another table
- Use INNER JOIN when you need a result that matches both tables
- Use LEFT JOIN when you wan to populate current table with additional data, without skipping rows in the original table
- Joins can accept multiple keys, so you are not limited to only one column to join
- Self join (joining table with itself) is a powerful technique to make some advanced calculations

# Window functions

In SQL you often need to calculate some measures over some tables. Like in the examples above, you wanted to calculate monthly revenue numbers, or split per country with tax amounts, etc. In all cases you used GROUP BY arrgeretion technique that does exactly that. However, sometimes you may need to perform calculations without performing aggregations. For example, recall the last example with rolling gross revenue where we didn't use GROUP BY in the final statement, insted we utilized JOIN to perform such calculation. That's why window functions exist.

**Window function** is a function that works with a subset of rows and perform a calculation in a separate column. It usually works with a subset of rows that are somehow related to the current row. And unlike grouping functions, it does not reduce the number of rows in a result set.

Window functions have special syntax that is a bit different from usuall functions in SQL:

```sql
<function_name>([<parameters>]) 
OVER (
	[PARTITION BY <column_set>,]
	[ORDER BY <column_set>,]
	[<frame_clause>]
)
```

Ok, I agree that it may look complicated. But in practice you will rarely use everything at once. Here is how it works:
1. First you specify a function name that you want to use with possible parameters (could be empty)
2. Next, every window function should be followed by OVER keyword, after which you will specify a "window" for your function
3. PARTITION BY clause will split the dataset into smaller groups/partitions by using specified columns. Window function will use these partitions to perform calculation. This is an optional clause (thus in square brakets) and may be not needed for some functions
4. ORDER BY clause will apply sorting during the calculation of window function. It's also an optional clause that may not be required
5. Lastly, you may specify a frame clause that will specifically separate rows for the window. Also optional

Roughly, we can split all window functions into three groups:
- **Ranking functions** – when you want to get a ranking for the rows
- **Aggregating functions** – as name suggests, when you need to calculate an aggregated metric
- **Offset functions** – when you want to access neighbor rows from the current row

## Ranking functions

Most useful ranging functions are ROW_NUMBER(), RANK() and DENSE_RANK().

ROW_NUMBER() will simply attach a sequential number to each row over some sorting condition. For example, let's calculate serial number for our users within each country:

```sql
SELECT
	id,
	first_name,
	last_name,
	reg_date,
	country ,
	ROW_NUMBER() OVER (PARTITION BY country ORDER BY reg_date) AS rn
FROM users
```

You'll get something like this:

```
id  |first_name |last_name |reg_date           |country     |rn
----+-----------+----------+-------------------+------------+--
9016|Andrea     |Smith     |2016-05-14 19:47:00|Afghanistan | 1
6436|Paul       |Heath     |2016-06-22 13:40:48|Afghanistan | 2
8243|Michelle   |Avery     |2016-07-01 23:31:22|Afghanistan | 3
5981|Dawn       |Gray      |2016-08-06 01:45:39|Afghanistan | 4
..
3203|Anthony    |Chung     |2016-05-17 16:55:53|Albania     | 1
7162|Cynthia    |Ross      |2016-06-26 08:36:52|Albania     | 2
9119|Richard    |Jones     |2016-07-06 11:55:35|Albania     | 3
7001|Janice     |White     |2016-07-14 22:29:41|Albania     | 4
...
```

What is happening here? Let me highlight some important part of the query:
1. First of all, ROW_NUMBER() is a window function that apply sequential number to the rows
2. Function is applied to the window that is limited by the `country` columns (PARTITION BY statement)
3. To apply sequential number in a correct order, we specify sorting column `reg_date` (ORDER BY statement)
4. Row counter breaks when there no row in the current window and starts over in a new window

RANK() function works similarly to ROW_NUMBER(), but if there are two rows with the same values they both get the same rank and skip the next rank.

DENSE_RANK() also respects row with the same rank (and assign it to both rows), however it doeesn not skip the next rank and assign it to the following row.

## Aggregation function

They help you calculate a value within a group. If you won't spcify the partition group it will work as running aggregation.

Her you could use a familiar functions like SUM, COUNT, AVG, MIN, MAX, etc.

For example, to calculate a running total amount per month you could write:

```sql
WITH table_monthly_sales AS (
	SELECT
		strftime('%Y-%m', event_date) AS report_month,
		sum(gross_revenue) AS gross_revenue
	FROM payments
	GROUP BY 1
)
SELECT
	report_month,
	gross_revenue,
	sum(gross_revenue) OVER (ORDER BY report_month) AS rolling_gross_revenue
FROM table_monthly_sales
```

Now recall the example 8 from the previous section about joins and compare two approaches.

If you would want to reset the running total for each year you could simple add PARTITION BY to the above example.

```sql
WITH table_monthly_sales AS (
	SELECT
		strftime('%Y-%m', event_date) AS report_month,
		strftime('%Y', event_date) AS report_year,
		sum(gross_revenue) AS gross_revenue
	FROM payments
	GROUP BY 1
)
SELECT
	report_month,
	gross_revenue,
	sum(gross_revenue) OVER (PARTITION BY report_year ORDER BY report_month) AS rolling_gross_revenue
FROM table_monthly_sales
```

Now, if you would want to calculate a contribution of each month to the yearly number, you first need to calculate a total yearly amount. And then with simple math you could see how much each month contributed:

```sql
WITH table_monthly_sales AS (
	SELECT
		strftime('%Y-%m', event_date) AS report_month,
		strftime('%Y', event_date) AS report_year,
		sum(gross_revenue) AS gross_revenue
	FROM payments
	GROUP BY 1
)
SELECT
	report_month,
	gross_revenue,
	sum(gross_revenue) OVER (PARTITION BY report_year) AS total_yearly_amount,
	gross_revenue / sum(gross_revenue) OVER (PARTITION BY report_year) AS contribution
FROM table_monthly_sales
```

Pay attention that SUM was used with partitioning, but without ordering.

## Offset functions

Sometimes you may need to access data from next or previous rows in the current row.

To access previous row you can use `LAG()` function, to access next row you use `LEAD()`. Order of rows will matter for that functions so not forget to specify `ORDER BY` clause for your window.

```sql
SELECT
	id,
	reg_date,
	country,
	LAG(id) OVER (ORDER BY reg_date) AS previous_user_id,
	LEAD(id) OVER (PARTITION BY country ORDER BY reg_date) AS next_user_from_country
FROM
	users
```

Both functions support offsets if you need to skip more than one row. Also, if previous/next value does not exist the function will return `NULL`. Yet you can specify what value should be returned by default. Here is how it works:

```sql
LAG(<column_name>, <offset>, <default_value>) OVER (...)
```

# SQL and beyond

Whuh, it was a chapter, right? I hope you learned a thing or two.

In everyday work this chapter will be enough to cover at least 95% of daily tasks. Data pipelines and reports made of SQL won't be a problem anymore.

Once you start using all these functions on a daily basis you will uncover that many of them have more additional abilities or hidden features. I leave such discoveries to you as this is a part of your journey.

Yet, I'd like to say that SQL can be much more than I explained in those two chapters. For example:

- Tables creation or DDL (Data Definition Language). Basically it is a special syntax that allows you manage your tables (create, delete, change, etc)
- Advanced grouping with CUBE and ROLLUP and advanced filtering with QUALIFY. Go beyond simple GROUP BY and WHERE. Make sure that your database supports those :)
- Procedure languages and transactions. Even more control over your data and abilities. Also highly depends on the database you are using, different DBs have different languages and syntaxes
- Security. Who should see the data? who can change the data? Access rights and many more work is done by IT departments to ensure that sensetive data is hidden from unwanted eyes and needed data is exposed to proper people.
- many many more topics :)

Lastly, giving you a couple of sources where you can dive deeper and find some more knowledge:
- https://github.com/pingcap/awesome-database-learning
- https://awesome-tech.readthedocs.io/databases/


Happy learning and SQL-ing!

---

If you made this far and have any questions feel free to open a ticket [here](https://github.com/oleg-agapov/data-engineering-book/issues).

Also, any other feedback is appreciated via [this form](https://docs.google.com/forms/d/e/1FAIpQLSeYSxyQcNyXIyQeD1DtR6q2zHO7heGGUQ36PqW--XdRL01Wqg/viewform).

[Table of content](/README.md)
