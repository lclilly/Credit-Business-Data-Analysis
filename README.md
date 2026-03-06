# Lending Portfolio Credit Analysis
### End-to-End Data Analytics Project | SQL Server · Power BI · DAX

---

## Project Overview

This project simulates the work of a data analyst embedded in the credit department of a lending institution. It answers the questions that C-suite executives in lending actually ask — not textbook questions, but the survival, scale, and signal questions that drive real portfolio decisions.

The analysis covers five executive themes:
- Are we making money or just issuing loans?
- How risky is this portfolio?
- Are our collections strategies working?
- Are we growing intelligently?
- What early warning signals are emerging?

---

## Tools Used

| Tool | Purpose |
|------|---------|
| Microsoft SQL Server | Data storage, cleaning, and analysis |
| Power BI Desktop | Dashboard and visualizations |
| DAX | Calculated measures and columns |
| Power Query | Data transformation and modelling |
| Excel | Raw dataset source |

---

## Dataset

The dataset was purpose-built for this project to simulate a realistic lending portfolio. It contains intentional data quality issues to reflect real-world data engineering challenges.

**4 tables, 7,800+ records across:**

| Table | Records | Description |
|-------|---------|-------------|
| Loan_Book | 2,000 | Core loan-level data — borrower, product, status, balances |
| Repayment_History | 5,000 | Payment-by-payment transaction records |
| Collections_Log | 800 | Collections actions, outcomes, recovery amounts |
| Portfolio_Summary | 60 months | Aggregated monthly executive metrics (2020–2024) |

**Data quality issues addressed:**
- 15 duplicate Loan_IDs (retained — identified as repeat borrowers)
- Mixed date formats across three conventions (YYYY-MM-DD, MM/DD/YYYY, DD-Mon-YYYY)
- Interest rates entered as percentages instead of decimals (~80 rows)
- Credit scores with 'N/A' strings and nulls
- Inconsistent casing and trailing spaces across Region, Product_Type, Loan_Status
- Negative outstanding balances (converted to zero — overpaid/closed loans)
- Cure_Flag encoded eight different ways (Y, N, Yes, No, y, n, 1, 0)

---

## Data Cleaning — SQL Server

All cleaning was performed in SQL Server using T-SQL. Key decisions and reasoning:

**Why the 15 duplicate Loan_IDs were retained:**
Standard practice is to remove duplicates. However, the investigation revealed these were repeat borrowers holding multiple products under the same Loan_ID — for example, a customer with both a Business Loan and a Mortgage. Removing them would have deleted real portfolio activity and understated repeat borrower performance. They were retained and flagged.

**Why negative outstanding balances were converted to zero, not absolute values:**
A negative outstanding balance in a lending system indicates the borrower overpaid — the loan is effectively closed. The true balance is zero, not the absolute value of the negative number. Using ABS() would have inflated the portfolio size with phantom debt and distorted every downstream risk ratio.

---

## Analysis — SQL Server

Analysis queries are organised by C-suite question:

1. **Portfolio Health** — total book size, yield, NIM trend, product and segment breakdown
2. **Risk Analysis** — PAR30, PAR90, NPL ratio, default rates by region/segment, vintage analysis
3. **Collections Effectiveness** — cure rates, recovery ROI, agent performance, payment behaviour
4. **Growth Intelligence** — disbursement trends, geographic growth, repeat vs new borrowers
5. **Early Warning Signals** — rising DPD averages, PAR spike detection, late payment trends

---

## Data Model — Power BI

| Relationship | Type | Join Column |
|-------------|------|-------------|
| Loan_Book → Repayment_History | Many to Many | Loan_ID |
| Loan_Book → Collections_Log | Many to Many | Loan_ID |
| Portfolio_Summary | Standalone | — |

**Why Many-to-Many:**
The decision to retain duplicate Loan_IDs for repeat borrowers means Loan_ID is not unique in the Loan_Book table. This creates a many-to-many relationship in Power BI, which is a known and documented limitation of the repeat borrower data decision.

---

## Dashboard — Power BI (4 Pages)

### Page 1 — Portfolio Health
**Headline findings:**
- Total portfolio: $130M | NIM: 8.03% | Cost of Risk: 2.75%
- Risk-adjusted margin: 5.28% — portfolio is generating significantly more than it is losing
- Business Loans lead the book at 26.25%, followed by Auto Loans at 25.55%
- Consistent portfolio growth from $800M to $1.4B between 2020 and 2024

### Page 2 — Risk Analysis
**Headline findings:**
- PAR30: 42.97% — elevated; nearly half the portfolio is at least 30 days past due
- PAR90 and NPL Ratio: 23.78% — a quarter of the book is seriously delinquent
- Nakuru is the riskiest region at 48.14% PAR30; Nairobi is healthiest at 38.63%
- Micro borrowers default at 18.72% — nearly 6 points above Corporate borrowers
- Vintage analysis shows no single cohort is catastrophically worse — credit quality issues are systemic rather than concentrated in one growth phase
- $32M sits at 180+ DPD — significant tail risk requiring urgent collections attention

### Page 3 — Collections Effectiveness
**Headline findings:**
- Recovery ROI: 17.84 — for every $1 spent on collections, $17.84 is recovered
- Cure Rate: 0.01 — critical red flag; collections is recovering money but not rehabilitating borrowers
- Late payment rate consistently between 68–74% across all five years — no improvement trend
- 64.66% of payments made in full; 15.26% partial; 15.18% missed
- Top collectors: AG001 and AG009 at $2.8M each recovered

### Page 4 — Growth Intelligence
**Headline findings:**
- $233M disbursed | Average loan size: $117K
- Repeat Borrower Ratio: 4.54 — strong customer loyalty signal
- Repeat borrowers consistently outpace new borrowers — mature, trusted lending operation
- All five regions within $10M of each other in disbursements — healthy geographic diversification
- All four product types growing consistently — no product collapse or dangerous spike

---

## Key Recommendations

1. **Investigate PAR30 urgently.** A 42.97% PAR30 alongside a healthy NIM is a warning that profitability is currently masking a deteriorating book. If delinquency trends continue, cost of risk will rise and erode the margin.

2. **Shift collections from recovery to rehabilitation.** A cure rate of 0.01 means the collections function is almost entirely reactive. Early intervention strategies — SMS reminders, restructuring offers before 90 DPD — could improve cure rates and reduce the 180+ DPD tail.

3. **Apply tighter credit screening to Micro borrowers.** An 18.72% default rate in the Micro segment is significantly above other segments. Either credit standards need tightening or a dedicated risk model for this segment is required.

4. **Monitor Nakuru and Eldoret closely.** Both regions have PAR30 above 45%. Geographic concentration of risk at this level warrants regional portfolio reviews and potentially adjusted underwriting criteria.

5. **Protect the repeat borrower base.** A ratio of 4.54 is a genuine competitive asset. Delinquency-driven write-offs in loyal customer segments would damage this ratio and increase customer acquisition costs.

---

## Files in This Repository

```
├── data/
│   └── lending_portfolio_dataset.xlsx       # Raw dataset
├── sql/
│   ├── lending_data_cleaning_tsql.sql       # Data cleaning queries
│   └── lending_analysis_tsql.sql            # Analysis queries
├── powerbi/
│   └── CreditAnalysis.pbix                  # Power BI dashboard file
├── exports/
│   └── CreditAnalysis.pdf                   # Dashboard export (4 pages)
└── README.md
```

---

## About This Project

This project was built as part of a data analyst portfolio targeting credit and financial services roles. Every decision — from data cleaning to dashboard design — was made with the lens of what a credit analyst or Chief Credit Officer would actually need to see.

The goal was not to demonstrate technical skill in isolation. The goal was to demonstrate business judgment through data.

---

*Open to Data Analyst opportunities in credit, lending, and financial services.*
*Let's connect: [Your LinkedIn URL]* 
