# 🎯 E-Commerce Transaction RFM Analysis

This repository presents an **RFM (Recency, Frequency, Monetary)** analysis conducted on e-commerce transaction data, covering the period from **December 2010 to December 2011**. The dataset contains over **500,000 transactions** from a UK-based retailer specializing in unique gifts. Key features include invoice numbers, product descriptions, quantities, prices, and customer IDs, making it ideal for analyzing customer behavior.

---

## 📂 Dataset Source  
The dataset was originally sourced from the [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/index.php) and is also available on [Kaggle](https://www.kaggle.com/datasets/carrie1/ecommerce-data).

---

## 🎯 Objective  

The primary goal of this project was to **segment customers** using RFM analysis, focusing on the following metrics:  
- **Recency**: Days since the last purchase.  
- **Frequency**: Total number of purchases by a customer.  
- **Monetary**: Total spending of a customer within a valid range.  

---

## 🛠️ Methodology  

### 1. **Data Preparation**  
- The dataset was imported into **PostgreSQL** for structured analysis.  
- Invalid and missing data were handled during the preprocessing stage.

### 2. **RFM Analysis**  
- **Recency**: Calculated as the number of days since the last purchase.
- **Frequency**: Measured by the total number of purchases per customer.  
- **Monetary**: Assessed based on total customer spending, filtered within a valid range to avoid outliers.  

📄 **SQL queries** used for RFM calculations are available [here](https://github.com/beyzabasarir/E-Commerce-RFM-Analysis/blob/main/rfm-analysis.sql).

### 3. **Visualization**  
- Analysis results were exported to **Python** for visualization.  
- Bar charts and heatmaps were created to illustrate customer segmentation insights.  
📊 Check the **Python notebook** [here](https://github.com/beyzabasarir/E-Commerce-RFM-Analysis/blob/main/rfm_analysis_notebook.ipynb).

---

## 📊 Results  

The **RFM analysis** identified distinct customer segments:  
1. **High-Value Customers**: Loyal customers contributing significantly to revenue.  
2. **At-Risk Customers**: Customers showing signs of churn.  
3. **Low-Value Customers**: Customers with minimal engagement or spending.  

Below is the SQL code used for segmentation and a visualization of the final segmentation:  

### 📜 SQL Code:  

```sql
WITH recency AS (
  WITH max_dates AS (
    SELECT 
      customer_id, 
      MAX(invoicedate) AS last_purchase_date
    FROM rfm
    WHERE quantity > 0 AND customer_id IS NOT NULL
    GROUP BY customer_id
  )
  SELECT 
    customer_id,
    EXTRACT(DAY FROM ('2011-12-09 12:50:00'::DATE - last_purchase_date)) AS recency
  FROM max_dates
),
frequency AS (
  SELECT 
    customer_id,
    COUNT(*) AS frequency
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
),
monetary AS (
  SELECT 
    customer_id, 
    ROUND(SUM(quantity * unitprice)::NUMERIC, 0) AS monetary
  FROM rfm
  WHERE quantity > 0 AND customer_id IS NOT NULL
  GROUP BY customer_id
  HAVING ROUND(SUM(quantity * unitprice)::NUMERIC, 0) BETWEEN 10 AND 10000
)
-- Segmenting the customers based on RFM scores
SELECT 
  Segment,
  COUNT(customer_id) AS customer_count
FROM (
  SELECT 
    customer_id,
    recency_score::TEXT || '-' || frequency_score::TEXT || '-' || monetary_score::TEXT AS rfm_score,
    CASE
      WHEN recency_score = 5 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'High-Value Customers'
      WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
      WHEN recency_score <= 3 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'At-Risk Customers'
      ELSE 'Low-Value Customers'
    END AS Segment
  FROM (
    SELECT 
      r.customer_id,
      NTILE(5) OVER (ORDER BY r.recency DESC) AS recency_score,
      CASE
        WHEN f.frequency >= 1 AND f.frequency <= 10 THEN 1
        WHEN f.frequency > 10 AND f.frequency <= 50 THEN 2
        WHEN f.frequency > 50 AND f.frequency <= 200 THEN 3
        WHEN f.frequency > 200 AND f.frequency <= 1000 THEN 4
        ELSE 5
      END AS frequency_score,
      NTILE(5) OVER (ORDER BY m.monetary ASC) AS monetary_score
    FROM recency r
    INNER JOIN frequency f ON r.customer_id = f.customer_id
    INNER JOIN monetary m ON r.customer_id = m.customer_id
  ) AS rfm_scores
) AS segmented_customers
GROUP BY Segment
ORDER BY customer_count DESC;
```

## 📊 Visualization
Below is a visualization showcasing the customer segments derived from the analysis:  

![RFM Analysis Customer Segmentation](https://github.com/beyzabasarir/E-Commerce-RFM-Analysis/blob/main/customer-segmentation.png).

---

## 🧩 Key Insights  

The analysis highlights distinct customer segments, emphasizing the following:  

- **At-Risk Customers (1,696 customers)**: These customers were once engaged but have recently become inactive. Targeted campaigns and personalized offers could help bring them back.
- **Low-Value Customers (1,508 customers)**: This group shows limited engagement and spending. It may not be worth prioritizing resources here, but monitoring their behavior can uncover future opportunities.
- **Loyal Customers (812 customers)**:These customers are consistently engaged. Keeping them satisfied with relevant communication and ongoing value is key to maintaining their loyalty. 
- **High-Value Customers (215 customers)**: Though small in number, these customers are highly profitable. Exclusive offers and tailored rewards can strengthen these valuable relationships.

---

## 🔗 Repository Links  

- **[SQL Analysis](https://github.com/beyzabasarir/E-Commerce-RFM-Analysis/blob/main/rfm-analysis.sql)**  
- **[Python Notebook](https://github.com/beyzabasarir/E-Commerce-RFM-Analysis/blob/main/rfm_analysis_notebook.ipynb)**  

---

Feel free to explore the repository and reach out with any questions or feedback! 😊 Thank you for your time and interest!
