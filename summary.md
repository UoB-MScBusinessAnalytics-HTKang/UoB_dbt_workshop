# UoB DBT Workshop

## Analytics Questions
* **Primary Question:** How long does it take for customers to repurchase, and what is the churn vs. loyalty distribution across stores?
* **Supporting Questions:**
  1. What percentage of customers are one-time purchasers (churned) versus frequent buyers (VIPs)?
  2. What is the average repurchase interval (`days_since_prior_order`) for loyal customers?
  3. Does the customer retention pattern differ when scaled across multiple stores?

---

## Model Architecture

### Staging Layer (`models/staging/`)
* Standardises and cleans raw tables (`raw_orders`, `raw_stores`, etc.) with basic casting and renaming into views.

### Intermediate Layer (`models/intermediate/int_customer_order_sequenced.sql`)
* Generates user-level purchase sequences partitioned by both `store_id` and `customer_id` for multi-store scalability.
* Calculates day gaps between sequential orders using `LAG()` and `DATE_DIFF()`.

### Marts Layer (`models/marts/fct_customer_order_insights.sql`)
* Enriches the sequenced order data with `store_name` via a `LEFT JOIN` for final BI consumption.
* Materialised as a table for optimal query performance.

---

## Data Quality Testing
Configured in `models/marts/schema.yml` using dbt 2.0 argument syntax:

* **Core Tests (Column-level):**
  * `order_id`: `unique` and `not_null` (Primary Key constraint).
  * `customer_id` & `store_id`: `not_null` (Foreign Key constraints).
  * `purchase_type`: `accepted_values` (Strictly restricted to `['First-time', 'Repeat']`).
* **Business Logic Test (Model-level):**
  * `dbt_utils.expression_is_true`: Assures that `days_since_prior_order >= 0` to block negative intervals or broken timelines.

---

## Insights with Evidence
Based on the final mart query aggregation:

| store_name | total_unique_customers | one_time_churn_rate_pct | vip_customer_count | avg_purchase_frequency | vip_avg_return_window_days |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Philadelphia | 128 | 7.8% | 105 | 5.4 times | 2.7 days |

* **Evidence-based Insight:** The Philadelphia store shows exceptional customer retention. Only **7.8%** of customers churn after their first purchase, while **82% (105 out of 128)** become VIPs (3+ orders). 
* **Behavioural Pattern:** Once a customer enters the VIP tier, their velocity accelerates significantly, returning to purchase every **2.7 days** on average.

---

## Actionable Next Steps
* **Automate Hyper-Fast CRM Trigger:** Since the VIP return window is extremely tight (2.7 days), configure an automated marketing push notification at the **48-hour mark** post-purchase if a repeat customer has not ordered again.
