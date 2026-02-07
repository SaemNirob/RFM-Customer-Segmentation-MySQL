USE RFM_SALES;  -- Select database

-- Quick look at raw data
SELECT * FROM SAMPLE_SALES_DATA LIMIT 20;

-- Understand data timeline (business period)
SELECT MIN(str_to_date(ORDERDATE, '%d/%m/%y')) FROM SAMPLE_SALES_DATA; -- FIRST BUSINESS DAY: 2003-01-06
SELECT MAX(str_to_date(ORDERDATE, '%d/%m/%y')) FROM SAMPLE_SALES_DATA; -- LAST BUSINESS DAY: 2005-05-31

-- Current date (system date)
SELECT CURDATE(); -- Today



-- Customer level overview:
-- 1) Last purchase date
-- 2) Frequency = number of unique orders
-- 3) Monetary = total sales amount
SELECT 
	CUSTOMERNAME,
    MAX(STR_TO_DATE(ORDERDATE, '%d/%m/%y')) AS LAST_ORDER_DATE,
    COUNT(DISTINCT ORDERNUMBER) AS F_VALUE,
    ROUND(SUM(SALES),0) AS M_Value
FROM SAMPLE_SALES_DATA
GROUP BY CUSTOMERNAME;



-- SubQuery to calculate:
-- R_VALUE = days since last purchase (based on max orderdate in dataset)
-- F_VALUE = distinct order count
-- M_VALUE = total sales
-- Then filter customers whose recency is between 50 and 100 days
SELECT * FROM
(SELECT 
	CUSTOMERNAME,
    DATEDIFF((SELECT MAX(str_to_date(ORDERDATE, '%d/%m/%y')) FROM SAMPLE_SALES_DATA), 
             MAX(STR_TO_DATE(ORDERDATE, '%d/%m/%y'))) AS R_VALUE,
    COUNT(DISTINCT ORDERNUMBER) AS F_VALUE,
    ROUND(SUM(SALES),0) AS M_Value
FROM SAMPLE_SALES_DATA
GROUP BY CUSTOMERNAME) AS SUMMARY_TABLE
WHERE R_VALUE BETWEEN 50 AND 100;



-- Final RFM View:
-- Step 1: Build customer summary (Recency, Frequency, Monetary)
-- Step 2: Assign scores using NTILE(5) window function
-- Step 3: Combine scores (e.g., 555)
-- Step 4: Map score combinations into business segments

CREATE OR REPLACE VIEW RFM AS
WITH CUSTOMER_SUMMARY_TABLE AS
(SELECT 
	CUSTOMERNAME,
    DATEDIFF((SELECT MAX(str_to_date(ORDERDATE, '%d/%m/%y')) FROM SAMPLE_SALES_DATA), 
             MAX(STR_TO_DATE(ORDERDATE, '%d/%m/%y'))) AS RECENCY_VALUE,
    COUNT(DISTINCT ORDERNUMBER) AS FREQUENCY_VALUE,
    ROUND(SUM(SALES),0) AS MONETARY_VALUE
FROM SAMPLE_SALES_DATA
GROUP BY CUSTOMERNAME),

RFM_SCORE AS
(SELECT 
	S.*,
    -- R_SCORE, F_SCORE, M_SCORE are computed using quintiles (1–5)
    NTILE(5) OVER(ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
    NTILE(5) OVER(ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
    NTILE(5) OVER(ORDER BY MONETARY_VALUE ASC) AS M_SCORE
FROM CUSTOMER_SUMMARY_TABLE AS S),

RFM_COMBINATION_SCORE AS
(SELECT 
	R.*,
    -- Total score (simple sum)
    (R_SCORE+F_SCORE+M_SCORE) AS TOTAL_RFM_SCORE,
    -- Combined code (example: 555)
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION
FROM RFM_SCORE AS R)

-- Segment assignment based on RFM score combinations
SELECT
	RC.*,
    CASE
		WHEN RFM_SCORE_COMBINATION IN (455, 542, 544, 552, 553, 452, 545, 554, 555) THEN 'Champions'
        WHEN RFM_SCORE_COMBINATION IN (344, 345, 353, 354, 355, 443, 451, 342, 351, 352, 441, 442, 444, 445, 453, 454, 541, 543, 515, 551) THEN 'Loyal Customers'
        WHEN RFM_SCORE_COMBINATION IN (513, 413, 511, 411, 512, 341, 412, 343, 514) THEN 'Potential Loyalists'
        WHEN RFM_SCORE_COMBINATION IN (414, 415, 214, 211, 212, 213, 241, 251, 312, 314, 311, 313, 315, 243, 245, 252, 253, 255, 242, 244, 254) THEN 'Promising Customers'
        WHEN RFM_SCORE_COMBINATION IN (141, 142,143,144,151,152,155,145,153,154,215) THEN 'Needs Attention'
        WHEN RFM_SCORE_COMBINATION IN (113, 111, 112, 114, 115) THEN 'About to Sleep'
        ELSE 'OTHER'
	END AS CUSTOMER_SEGMENT
FROM RFM_COMBINATION_SCORE AS RC;


-- Verify final view output
SELECT * FROM RFM;


-- Segment-wise revenue summary:
-- Total monetary value + average monetary value per segment
SELECT 
	CUSTOMER_SEGMENT,
    ROUND(SUM(MONETARY_VALUE), 0) AS TOTAL_MONETARY_VALUE,
    ROUND(AVG(MONETARY_VALUE), 0) AS AVERAGE_MONETARY_VALUE
FROM RFM
GROUP BY 1
ORDER BY 2 DESC;


-- Quick preview of both tables
SELECT * FROM SAMPLE_SALES_DATA LIMIT 10;
SELECT * FROM RFM LIMIT 10;

-- Segment-wise sales performance:
-- Join raw sales with RFM segment labels
SELECT 
	CUSTOMER_SEGMENT,
    SUM(QUANTITYORDERED) AS TOTAL_QUANTITY_ORDERED,
    ROUND(SUM(SALES),0) AS TOTAL_SALES_AMOUNT
FROM SAMPLE_SALES_DATA AS S
	LEFT JOIN RFM AS R ON S.CUSTOMERNAME = R.CUSTOMERNAME
GROUP BY 1
ORDER BY 2 DESC;


























