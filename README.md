# RFM Customer Segmentation (MySQL)

Customer segmentation using **RFM (Recency, Frequency, Monetary)** analysis in **MySQL 8+**.  
This project creates a reusable **`RFM` VIEW** that scores customers with quintiles and assigns them into business segments such as **Champions**, **Loyal Customers**, **Potential Loyalists**, etc.

---

## Project Overview

### Key Features
- Builds customer-level RFM metrics from transaction data
- Uses `NTILE(5)` for scoring (quintiles)
- Generates a combined RFM code (e.g., `555`)
- Maps RFM codes into business-friendly segments
- Provides segment-wise performance summaries

---

## Dataset & Schema

**Database:** `RFM_SALES`  
**Table:** `SAMPLE_SALES_DATA`

### Required Columns
| Column | Description |
|-------|-------------|
| `CUSTOMERNAME` | Customer name/identifier |
| `ORDERDATE` | Order date (string) in `%d/%m/%y` |
| `ORDERNUMBER` | Unique order identifier |
| `SALES` | Sales amount |
| `QUANTITYORDERED` | Quantity ordered |

### Business Timeline (from dataset)
- First order date: **2003-01-06**
- Last order date: **2005-05-31**

> **Important:** Recency is computed relative to the **maximum order date available in the dataset**, not the current system date.

---

## RFM Logic

### Step 1 — Customer Summary
For each customer:
- **Recency:** days since last purchase  
- **Frequency:** count of distinct orders  
- **Monetary:** total sales amount  

### Step 2 — RFM Scoring (Quintiles)
Scores are assigned using `NTILE(5)`:
- `R_SCORE` from `RECENCY_VALUE`
- `F_SCORE` from `FREQUENCY_VALUE`
- `M_SCORE` from `MONETARY_VALUE`

### Step 3 — Score Combination
A combined RFM code is generated:
- Example: `555`, `455`, etc.

### Step 4 — Segmentation
RFM score combinations are mapped into segments:
- Champions  
- Loyal Customers  
- Potential Loyalists  
- Promising Customers  
- Needs Attention  
- About to Sleep  
- Other

---

## How to Run

### Requirements
- **MySQL 8+** (window functions required)
- Access to:
  - Database: `RFM_SALES`
  - Table: `SAMPLE_SALES_DATA`

### Run Steps
1. Select database:
   ```sql
   USE RFM_SALES;
