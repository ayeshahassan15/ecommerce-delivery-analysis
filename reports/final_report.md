# E-commerce Sales and Delivery Analysis

## 1. Problem statement
An online marketplace has late deliveries and unhappy customers. This project asks:
what drives late deliveries, how do delays affect review scores, which states,
sellers and categories perform best or worst, and how does revenue change over time?

## 2. Dataset overview
Olist Brazilian E-Commerce dataset (Kaggle): 9 related tables, about 99,000 orders
from Oct 2016 to Aug 2018.
- 96,470 orders were delivered and had a delivery date. Only these are used for delivery analysis.
- 8 orders were marked "delivered" but had no delivery date. They were excluded.
- Missing delivery dates on other orders are real (canceled, shipped, etc.). They were not filled in.
- Some orders have up to 3 reviews. Reviews were averaged per order to avoid double counting.
- Revenue = sum of item prices (freight excluded), counted from order items only.

## 3. Methodology
1. CSV files loaded into PostgreSQL (raw schema), with primary keys and foreign keys.
2. Checks: row counts match the CSVs, no orphan keys, no duplicate primary keys.
3. SQL analysis: CTEs, joins and window functions (LAG, RANK).
4. Python and Pandas: one row per order, delivery features added, cleaning function tested with Pytest.
5. Charts with Matplotlib and Seaborn.
6. Statistical tests with SciPy (Mann-Whitney U, Welch t-test, 95% confidence interval).
7. Interactive dashboard with Plotly (reports/dashboard.html).

## 4. Key findings
- **Revenue:** total 13.2M BRL. It grew strongly through 2017, jumped 52% in Nov 2017
  (Black Friday), then stayed fairly flat in 2018.
- **Categories:** the top 10 categories give about 62% of revenue. Health and beauty
  (9.3%) and watches and gifts (8.8%) lead.
- **Late deliveries:** 8.1% of orders are late. Lateness peaked in Nov 2017 (14.3%),
  Feb 2018 (16.0%) and Mar 2018 (21.4%).
- **Location:** late rates vary a lot by state. AL (about 24%) and MA (about 19%) are
  worst. RO (about 3%) is best. The worst states are in the northeast.
- **Reviews:** on-time orders average 4.29 stars. Late orders average 2.57.
- **Size of delay:** up to 3 days late, scores fall only a little (about 3.8).
  From 4 days late, scores fall sharply (about 2.3), and 8+ days late is about 1.7.

## 5. Statistical results
- H0: late and on-time orders have the same review scores. H1: they differ.
- Mann-Whitney U and Welch t-test: p-value far below 0.001. H0 is rejected.
- Difference in average score: 1.73 points (95% CI: 1.69 to 1.77).
- This is statistically significant and also large in practice: the median score is 5 for
  on-time orders and 2 for late orders.

## 6. Business recommendations
1. Focus on avoiding delays longer than 3 days. Customers forgive short delays but not long ones.
2. Improve delivery in the northeast states (AL, MA, PI, CE, SE), for example with
   more realistic delivery estimates or better carriers.
3. Prepare for peak periods. Late rates rose during Nov 2017 and early 2018.
4. Investigate Feb and Mar 2018 to find the cause of the spike in late orders.
5. Protect the top categories, which bring most of the revenue.

## 7. Limitations and future improvements
- The link between late delivery and low scores is not proof of cause. Distance, seller
  quality and product type may also play a part.
- Data covers only Oct 2016 to Aug 2018. Early months have very few orders.
- Only delivered orders were analyzed, so canceled and unavailable orders are not covered.
- A Plotly dashboard was used instead of Power BI because of storage limits.
- Future work: cohort retention analysis, freight cost vs satisfaction, Pandas vs Polars
  speed test, and a model to predict late deliveries.
  ## Additional analyses
- **Customer retention:** only 3.0% of customers ordered more than once. Customers whose first
  order was late came back slightly less often (2.51% vs 3.04%).
- **Freight cost:** shipping cost has almost no link with review scores (correlation -0.09).
  Delivery time has a stronger link (-0.23). Customers react to waiting, not to shipping price.
- **Late delivery prediction:** a gradient boosting model using only information known at purchase
  reached ROC AUC 0.70. The company's own delivery estimate was the most important feature.
  Adding seller state did not improve the result. The riskiest 10% of orders were late 9.0% of the
  time, against 5.3% on average, so the model can help rank risk but is too weak to rely on alone.
  Seller processing time and carrier data would likely be needed to improve it.