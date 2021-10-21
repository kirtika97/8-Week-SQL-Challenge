--CASE STUDY #1- DANNY'S DINNER
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
SELECT * FROM sales;

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
SELECT * FROM menu;

CREATE TABLE members ("customer_id" VARCHAR(1), "join_date" DATE);
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09'); 
SELECT * FROM members;

--Case Study Questions
--1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS "Total Amount Spent"
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

/* Customer A spent $76
   Customer B spent $74
   Customer C spent $36*/
   
   
--2. How many days has each customer visited the restaurant?
SELECT sales.customer_id, COUNT(DISTINCT(order_date)) AS "No. of days visited" FROM sales
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

/* Customer A visited 4 times
   Customer B visited 6 times
   Customer C visited 2 times*/
  
  
--3. What was the first item from the menu purchased by each customer?
WITH order_sales_cte AS
(SELECT customer_id, order_date, product_name,
 DENSE_RANK() OVER(PARTITION BY s.customer_id
 ORDER BY s.order_date) AS rank
 FROM sales AS s
 JOIN menu AS m
 ON s.product_id = m.product_id)
SELECT customer_id, product_name
FROM order_sales_cte
WHERE rank = 1
GROUP BY customer_id, product_name;

/* Customer A's first purchase was Curry and Sushi
   Customer B's first purchase was Curry
   Customer C's first purchase was Ramen*/
   
   
--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(sales.product_id) AS "purchase_count"
FROM menu 
JOIN sales 
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY purchase_count desc;
LIMIT 1;

/* Most purchased item was Ramen, it was purchased 8 times by all customers*/


--5. Which item was the most popular for each customer?
WITH most_popular_item_cte AS
(SELECT sales.customer_id,menu.product_name, count(sales.product_id) AS ordered_max,
DENSE_RANK() OVER(PARTITION BY sales.customer_id
ORDER BY count(sales.product_id) DESC) AS rank
FROM sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id, menu.product_name)
SELECT customer_id, product_name AS "Most Popular Item", ordered_max 
FROM most_popular_item_cte 
WHERE rank =1;

/* Most popular item of customer A and C was Ramen
 Customer B was indifferent to all of the items Ramen, Curry, Sushi*/



--6. Which item was purchased first by the customer after they became a member?
WITH member_first_purchase_cte AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,m2.product_name,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date) AS rank
   FROM sales AS s
   JOIN members AS m ON s.customer_id = m.customer_id
   JOIN menu AS m2 ON s.product_id = m2.product_id
   WHERE s.order_date >= m.join_date
)
SELECT join_date, customer_id, order_date, product_name FROM member_first_purchase_cte
WHERE rank = 1;

/* Customer A purchased Curry after becoming Member
   Customer B purchased Sushi after becoming Member*/



--7. Which item was purchased just before the customer became a member?
WITH purchase_before_member_cte AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,m2.product_name,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date DESC) AS rank
   FROM sales AS s
   JOIN members AS m ON s.customer_id = m.customer_id
   JOIN menu AS m2 ON s.product_id = m2.product_id
   WHERE s.order_date < m.join_date
)
SELECT join_date, customer_id, order_date, product_name
FROM purchase_before_member_cte
WHERE rank=1;
/*Customer A- sushi,curry
  Customer B-sushi*/

--8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS "Total Items", SUM(m.price) AS "Amount Spent"
FROM sales AS s
JOIN menu AS m ON s.product_id = m.product_id
JOIN members AS mm ON s.customer_id=mm.customer_id
WHERE s.order_date < mm.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;
/* Customer A spent $25 on 2 items
   Customer B spent $40 on 2 items before they became a member*/

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--how many points would each customer have?
WITH points_cte AS
 (
   SELECT s.customer_id, 
     CASE m.product_name 
	 WHEN 'sushi' THEN 2*10*m.price
    ELSE m.price*10
	  END
AS points
FROM sales as s JOIN menu as m ON s.product_id = m.product_id
  )
SELECT customer_id, SUM(points) AS "Total Points"
FROM points_cte
GROUP BY customer_id
ORDER BY customer_id;
--or
SELECT s.customer_id, 
     SUM(CASE m.product_name 
	 WHEN 'sushi' THEN 2*10*m.price
     ELSE m.price*10
	 END) AS points
FROM sales as s JOIN menu as m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
/* Customer A earned 860 points, 
   Customer B earned 940 points and 
   Customer C earned 360 points earned*/

--10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi -how many points do customer A and B have at the end of January?
SELECT s.customer_id, SUM(CASE
                               WHEN product_name = 'sushi' THEN 20 * price
                               WHEN order_date BETWEEN join_date AND join_date + 6 THEN 20 * price
                             ELSE 10 * PRICE
                              END) AS total_points
FROM members AS mm
LEFT JOIN sales AS s ON s.customer_id = mm.customer_id
LEFT JOIN menu as m ON m.product_id = s.product_id
WHERE order_date <= '2021-01-31'
GROUP BY s.customer_id;
/* Customer A has 1370 points
   Customer B has 820 points */
   
/*Bonus Questions: 
1. Join All The Things
Recreate the table with: customer_id, order_date, product_name, price, member (Y/N) */
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
  WHEN s.order_date < mm.join_date THEN 'N'
  WHEN s.order_date >= mm.join_date THEN 'Y'
  ELSE 'N'
END AS member
FROM sales AS s 
LEFT JOIN menu as m ON s.product_id=m.product_id 
LEFT JOIN members as mm ON s.customer_id = mm.customer_id
ORDER BY customer_id, order_date;

-- 2. Rank All The Things
WITH ranking_cte AS
(SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
  WHEN s.order_date < mm.join_date THEN 'N'
  WHEN s.order_date >= mm.join_date THEN 'Y'
  ELSE 'N'
END AS member
FROM sales AS s 
LEFT JOIN menu as m ON s.product_id=m.product_id 
LEFT JOIN members as mm ON s.customer_id = mm.customer_id
ORDER BY customer_id, order_date)
SELECT *,
CASE
    WHEN member ='N' THEN NULL
	ELSE 
	   RANK() OVER(PARTITION BY customer_id, member
				  ORDER BY order_date) 
	END AS ranking
FROM ranking_cte;
		