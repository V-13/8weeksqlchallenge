CREATE SCHEMA dannys_diner;


CREATE TABLE dannys_diner.sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO dannys_diner.sales
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

  SELECT MAX(product_id) FROM dannys_diner.sales

 EXEC sp_help 'dannys_diner.sales'

  CREATE TABLE dannys_diner.menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO dannys_diner.menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

SELECT * FROM dannys_diner.menu


CREATE TABLE dannys_diner.members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

DROP TABLE members

INSERT INTO dannys_diner.members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  -- 1. What is the total amount each customer spent at the restaurant?

  SELECT * FROM dannys_diner.members
  SELECT * FROM dannys_diner.menu
  SELECT * FROM dannys_diner.sales

  SELECT * FROM dannys_diner.sales
  JOIN dannys_diner.menu
  ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
  WHERE dannys_diner.sales.customer_id ='A'

  SELECT dannys_diner.sales.customer_id,SUM(price) AS Total_Spent FROM dannys_diner.sales
  JOIN dannys_diner.menu
  ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
  GROUP BY dannys_diner.sales.customer_id

  -- 2. How many days has each customer visited the restaurant?

  SELECT * FROM dannys_diner.sales
  WHERE dannys_diner.sales.customer_id ='C'

  SELECT dannys_diner.sales.customer_id , COUNT(DISTINCT order_date) 
  FROM dannys_diner.sales
  GROUP BY dannys_diner.sales.customer_id


  -- 3. What was the first item from the menu purchased by each customer?

 
  SELECT * FROM dannys_diner.sales
  SELECT * FROM dannys_diner.menu

 
 WITH cte_purchase
 AS
 (
 SELECT *,
 ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS purchase_by_order
  FROM dannys_diner.sales
 )

  SELECT  cte_purchase.customer_id,dannys_diner.menu.product_name
  FROM 
  cte_purchase
  JOIN 
  dannys_diner.menu
  ON cte_purchase.product_id = dannys_diner.menu.product_id
  WHERE cte_purchase.purchase_by_order = 1


 -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


 SELECT * FROM dannys_diner.sales
 SELECT * FROM dannys_diner.menu

 WITH cte_purchase
 AS
 (
 SELECT dannys_diner.sales.customer_id AS Customer,dannys_diner.menu.product_name AS Prod_Name,COUNT(dannys_diner.menu.product_name) AS No_of_Purchase FROM dannys_diner.sales
 JOIN dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
 GROUP BY dannys_diner.sales.customer_id,dannys_diner.menu.product_name
 
 )
--SELECT * FROM cte_purchase
--ORDER BY Customer

 --SELECT TOP 1 Prod_Name, No_of_Purchase
 --FROM cte_purchase
 --ORDER BY No_of_Purchase DESC


 SELECT Customer,Prod_Name,No_of_Purchase
 FROM cte_purchase
 WHERE Prod_Name  = (SELECT TOP 1 Prod_Name FROM cte_purchase ORDER BY No_of_Purchase DESC)


 -- 5. Which item was the most popular for each customer?

 WITH cte_purchase_rank
 AS
 (
 SELECT customer_id AS customer,product_name AS Product ,COUNT(product_name) AS No_of_Purchase,
 DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS Top_Purchase_Rank
 FROM dannys_diner.sales
 JOIN
 dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
 GROUP BY customer_id,product_name
 )

 SELECT customer,Product
 FROM cte_purchase_rank
 WHERE Top_Purchase_Rank =1
 

 -- 6. Which item was purchased first by the customer after they became a member?

 SELECT * FROM dannys_diner.members
 SELECT * FROM dannys_diner.menu
 SELECT * FROM dannys_diner.sales

 WITH cte_firstorder
 AS
 (
SELECT dannys_diner.sales.customer_id,
	   product_name,
	   DENSE_RANK() OVER(PARTITION BY dannys_diner.sales.customer_id ORDER BY order_date) AS Order_order 
	   FROM dannys_diner.sales
  JOIN dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
  JOIN dannys_diner.members
 ON dannys_diner.sales.customer_id = dannys_diner.members.customer_id
 WHERE order_date >= join_date
 )
 SELECT customer_id,product_name
 FROM cte_firstorder
 WHERE Order_order = 1

 -- 7. Which item was purchased just before the customer became a member?

 WITH cte_lastorder
 AS
 (
 SELECT dannys_diner.sales.customer_id AS customer ,product_name AS Product,
	   DENSE_RANK() OVER(PARTITION BY dannys_diner.sales.customer_id ORDER BY order_date DESC) AS Order_order 
	   FROM dannys_diner.sales
  JOIN dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
  JOIN dannys_diner.members
 ON dannys_diner.sales.customer_id = dannys_diner.members.customer_id
 WHERE order_date < join_date
 )

 SELECT customer,Product,Order_order
 FROM cte_lastorder
 WHERE Order_order=1


 -- 8. What is the total items and amount spent for each member before they became a member?

 
 SELECT dannys_diner.sales.customer_id,SUM(price) AS Money_Spent
	   FROM dannys_diner.sales
  JOIN dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
  JOIN dannys_diner.members
 ON dannys_diner.sales.customer_id = dannys_diner.members.customer_id
 WHERE order_date < join_date
 GROUP BY dannys_diner.sales.customer_id
 

 -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

 WITH cte_Points
 AS
 (
 SELECT dannys_diner.sales.customer_id AS customer,
		CASE
			WHEN product_name = 'sushi' THEN price*10*2
			WHEN product_name = 'curry' THEN price*10
			WHEN product_name = 'ramen' THEN price*10
		END AS Points
	   FROM dannys_diner.sales
  JOIN dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
 )
 SELECT customer,SUM(Points) AS Total_Points
 FROM cte_Points
 GROUP BY customer

 -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
 --not just sushi - how many points do customer A and B have at the end of January?

 

 WITH cte_datediff
 AS
 (
 SELECT dannys_diner.sales.customer_id AS Customer,
		order_date,
		join_date,
		product_name,
		price,
		DATEDIFF(day,join_date,order_date) AS date_difference FROM dannys_diner.sales 
 JOIN dannys_diner.members
 ON dannys_diner.sales.customer_id = dannys_diner.members.customer_id
 JOIN dannys_diner.menu
 ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
 WHERE order_date>join_date AND order_date < '2021-02-01'
 )

 SELECT Customer,SUM(price*2*10) AS Points
 FROM cte_datediff
 GROUP BY Customer



