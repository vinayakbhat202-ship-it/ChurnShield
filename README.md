# ChurnShield — Customer Retention & Revenue Dashboard

An interactive Tableau dashboard analyzing customer churn risk, revenue trends, and retention patterns from e-commerce transaction data.

🔗 **Live Dashboard:** https://public.tableau.com/app/profile/vinayak.bhat7764/viz/Book1_17843636503980/ChurnShieldCustomerRetentionRevenueDashboard?publish=yes

## Overview

ChurnShield surfaces key customer behavior signals — who's at risk of churning, where revenue is concentrated, and how retention decays over time — to support data-driven retention strategy.

## Dashboard Components

- **KPI Summary** — Total Revenue, Active Customers, Average Order Value, Repeat Rate, Orders, Churn-Risk Customers (with month-over-month deltas)
- **Monthly Revenue & MoM Growth** — Dual-axis chart tracking revenue trend and growth rate over time
- **RFM Segments** — Customer segmentation by Recency, Frequency, Monetary value, comparing % of customers vs % of revenue per segment
- **Cohort Retention Heatmap** — Month-by-month retention decay across acquisition cohorts
- **Top Products by Revenue** — Highest-grossing products ranked by total revenue
- **Revenue by Country** — Geographic revenue distribution (treemap)
- **Orders by Hour of Day** — Order volume pattern across the day

## Data

Data is sourced from transaction-level e-commerce records, aggregated into the following tables:
- `kpis_monthly.csv`
- `revenue_monthly.csv`
- `rfm_pct.csv` / `rfm_segments.csv`
- `cohort_retention.csv`
- `top_products.csv`
- `revenue_by_country.csv`
- `orders_by_hour.csv`
- `monthly_repeat_rate.csv`

## Tools

- Tableau (Desktop / Public)
- SQL (for data aggregation)

## Key Insights

- UK accounts for the large majority of total revenue
- The "Champions" RFM segment drives a disproportionate share of revenue relative to customer count
- Retention drops sharply after the first month post-acquisition, then stabilizes
- Order volume peaks around midday, consistent with B2B purchasing patterns

---
Built by Vinayak Bhat
