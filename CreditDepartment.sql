CREATE DATABASE CreditDepartment

--Overview
SELECT TOP 10*
FROM Loan_Book;

SELECT TOP 10*
FROM Repayment_History;

SELECT TOP 10*
FROM Collections_Log;

SELECT TOP 10*
FROM Portfolio_Summary;

--STEP 1 DATA CLEANING
-- Cleaning Loan_Book Table

--Checking for duplicate Loan_IDs
SELECT Loan_ID, COUNT(*) AS how_many
FROM Loan_Book
GROUP BY Loan_ID
HAVING COUNT(*) >1;

-- Decided to keep the duplicate Loan_IDs because upon further investigation, they revealed that these were repeat borrowers

--Copying everything into a new Clean_Loan_Book table so that we can keep our original Loan_Book table just in case

SELECT*
INTO Clean_Loan_Book
FROM Loan_Book;

-- Fixing mixed date formats to proper date format
--Disbursement_Date Fix
ALTER TABLE Clean_Loan_Book
ADD Disbursement_Date_Clean DATE;

UPDATE Clean_Loan_Book
SET Disbursement_Date_Clean =
    CASE
        WHEN Disbursement_Date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN TRY_CONVERT(DATE, Disbursement_Date, 23)   -- YYYY-MM-DD
        WHEN Disbursement_Date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Disbursement_Date, 101)  -- MM/DD/YYYY
        WHEN Disbursement_Date LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Disbursement_Date, 106)  -- DD-Mon-YYYY
        ELSE NULL
    END;

--Maturity_Date Fix
ALTER TABLE Clean_Loan_Book
ADD Maturity_Date_Clean DATE;

UPDATE Clean_Loan_Book
SET Maturity_Date_Clean =
    CASE
        WHEN Maturity_Date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN TRY_CONVERT(DATE, Maturity_Date, 23)   -- YYYY-MM-DD
        WHEN Maturity_Date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Maturity_Date, 101)  -- MM/DD/YYYY
        WHEN Maturity_Date LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Maturity_Date, 106)  -- DD-Mon-YYYY
        ELSE NULL
    END;

--Fixing First_Payment_Date
ALTER TABLE Clean_Loan_Book
ADD First_Payment_Date_Clean DATE;

UPDATE Clean_Loan_Book
SET First_Payment_Date_Clean =
    CASE
        WHEN First_Payment_Date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN TRY_CONVERT(DATE, First_Payment_Date, 23)   -- YYYY-MM-DD
        WHEN First_Payment_Date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, First_Payment_Date, 101)  -- MM/DD/YYYY
        WHEN First_Payment_Date LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, First_Payment_Date, 106)  -- DD-Mon-YYYY
        ELSE NULL
    END;

--Fixing Interest Rate -- some rows entered as 18.5 percent instead of 0.185
--Convert column to decimal
ALTER TABLE Clean_Loan_Book
ADD Interest_Rate_Clean DECIMAL(10,6);

UPDATE Clean_Loan_Book
SET Interest_Rate_Clean =
    CASE
        WHEN TRY_CAST(Interest_Rate AS DECIMAL(10,6)) > 1
            THEN TRY_CAST(Interest_Rate AS DECIMAL(10,6)) / 100
        ELSE TRY_CAST(Interest_Rate AS DECIMAL(10,6))
    END;

--Checking all values are between 0 and 1
SELECT MIN(Interest_Rate_Clean), MAX(Interest_Rate_Clean)
FROM Clean_Loan_Book;

--Fixing Credit Score
--Replacing N/A and blanks with NULL
UPDATE Clean_Loan_Book
SET Credit_Score = NULL
WHERE UPPER(LTRIM(RTRIM(Credit_Score))) IN ('N/A', 'NA', 'NULL', '');

SELECT Credit_Score
FROM Clean_Loan_Book;

--Convert it to an integer column
ALTER TABLE Clean_Loan_Book
ADD Credit_Score_Clean INT;

UPDATE Clean_Loan_Book
SET Credit_Score_Clean = TRY_CAST(Credit_Score AS INT);

--Fixing Loan_Status, standardizing casing
UPDATE Clean_Loan_Book
SET Loan_Status =
    CASE UPPER(LTRIM(RTRIM(Loan_Status)))
        WHEN 'CURRENT'       THEN 'Current'
        WHEN '30-59 DPD'     THEN '30-59 DPD'
        WHEN '60-89 DPD'     THEN '60-89 DPD'
        WHEN '90+ DPD'       THEN '90+ DPD'
        WHEN 'WRITTEN OFF'   THEN 'Written Off'
        WHEN 'WRITTEN_OFF'   THEN 'Written Off'
		WHEN 'Written_off'   THEN 'Written Off'
        ELSE LTRIM(RTRIM(Loan_Status))
    END;

---- Checking distinct values — should only be the 5 clean statuses
SELECT DISTINCT Loan_Status FROM Clean_Loan_Book;

-- Fixing Region — removing spaces, standardizing to UPPER case
UPDATE Clean_Loan_Book
SET Region = UPPER(LTRIM(RTRIM(Region)));

SELECT DISTINCT Region
FROM Clean_Loan_Book;

-- Fixing Product_Type — removing spaces, standardizing casing
UPDATE Clean_Loan_Book
SET Product_Type = UPPER(LTRIM(RTRIM(Product_Type)));

SELECT DISTINCT Product_Type
FROM Clean_Loan_Book;

-- Fixing negative Outstanding_Balance values
-- Step 1: Add the flag column
ALTER TABLE Clean_Loan_Book
ADD Balance_Was_Negative BIT DEFAULT 0;

-- Step 2: Flag the negative rows
UPDATE Clean_Loan_Book
SET Balance_Was_Negative = 1
WHERE TRY_CAST(Outstanding_Balance AS DECIMAL(18,2)) < 0;

-- Step 3: Floor negatives to zero (not ABS)
UPDATE Clean_Loan_Book
SET Outstanding_Balance = CASE 
        WHEN TRY_CAST(Outstanding_Balance AS DECIMAL(18,2)) < 0 THEN 0
        ELSE Outstanding_Balance
    END
WHERE TRY_CAST(Outstanding_Balance AS DECIMAL(18,2)) < 0;

-- Fixing Days_Past_Due — no negatives allowed -- Thankfully there were no negative Days_Past_Due
UPDATE Clean_Loan_Book
SET Days_Past_Due = 0
WHERE TRY_CAST(Days_Past_Due AS INT) < 0;

--Checking our new Clean_Loan_Book
SELECT TOP 10 *
FROM Clean_Loan_Book;

--FIXING REPAYMENT HISTORY TABLE
--Copy raw to clean where we can make changes
SELECT*
INTO Clean_Repayment_History
FROM Repayment_History;

--Fixing date format
ALTER TABLE Clean_Repayment_History
ADD Payment_Date_Clean DATE;

UPDATE Clean_Repayment_History
SET Payment_Date_Clean =
	CASE
		WHEN Payment_Date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN TRY_CONVERT(DATE, Payment_Date, 23)
        WHEN Payment_Date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Payment_Date, 101)
        WHEN Payment_Date LIKE '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Payment_Date, 106)
        ELSE NULL
	END;

--Fixing Actual_Payment - N/A and Blanks to NULLs
UPDATE Clean_Repayment_History
SET Actual_Payment = NULL
WHERE UPPER(LTRIM(RTRIM(Actual_Payment))) IN ('N/A', 'NA', 'NULL', '');

--Fixing Payment_Method and Channel
UPDATE Clean_Repayment_History
SET Payment_Method = UPPER(LTRIM(RTRIM(Payment_Method))),
    Channel = UPPER(LTRIM(RTRIM(Channel)));

--Checking it's worked
SELECT DISTINCT Payment_Method, Channel
FROM Clean_Repayment_History;

-- Dealing for any Days_Late negatives -- Luckily, there were no negatives
UPDATE Clean_Repayment_History
SET Days_Late = 0
WHERE TRY_CAST(Days_Late AS INT) < 0;

-- Final Check
SELECT TOP 10 *
FROM Clean_Repayment_History;

--FIXING COLLECTIONS LOG TABLE
--Moving raw Collections_Log table into Clean_Collections_Log table where I can make changes
SELECT *
INTO Clean_Collections_Log
FROM Collections_Log;
--Creating new Action_Date_Clean with DATE format
ALTER TABLE Clean_Collections_Log
ADD Action_Date_Clean DATE;
--Updating Clean_Collections_Log and setting Action_Date_Clean with standardized dates
UPDATE Clean_Collections_Log
SET Action_Date_Clean =
	CASE
		WHEN Action_Date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN TRY_CONVERT(DATE, Action_Date, 23)
        WHEN Action_Date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN TRY_CONVERT(DATE, Action_Date, 101)
        ELSE NULL
    END;

SELECT TOP 10 Action_Date_Clean
FROM Clean_Collections_Log;

--Fixing the cure flag
ALTER TABLE Clean_Collections_Log
ADD Cured BIT;

UPDATE Clean_Collections_Log
SET Cured =
	CASE UPPER(LTRIM(RTRIM(Cure_Flag)))
        WHEN 'Y'   THEN 1
        WHEN 'YES' THEN 1
        WHEN '1'   THEN 1
        WHEN 'N'   THEN 0
        WHEN 'NO'  THEN 0
        WHEN '0'   THEN 0
        ELSE NULL
    END;

--Checking that Cured is fixed
SELECT DISTINCT Cured
FROM Clean_Collections_Log;

-- Fixing Amount_Recovered — blanks - NULL 
UPDATE Clean_Collections_Log
SET Amount_Recovered = NULL
WHERE LTRIM(RTRIM(ISNULL(Amount_Recovered, ''))) = '';


-- FINAL CHECK
SELECT TOP 10 *
FROM Clean_Collections_Log;

--PORTFOLIO SUMMARY CLEANING
-- Copying raw Portfolio_Summary into Porfolio_Summary_Clean where we can make changes
SELECT*
INTO Portfolio_Summary_Clean
FROM Portfolio_Summary;

DELETE Portfolio_Summary_Clean;

SELECT*
INTO Clean_Portfolio_Summary
FROM Portfolio_Summary;

-- Parse Month "YYYY-MM" into a proper DATE (first of month)
ALTER TABLE Clean_Portfolio_Summary
ADD Month_Start DATE;

UPDATE Clean_Portfolio_Summary
SET Month_Start = TRY_CONVERT(DATE, [Month] + '-01', 23);

-- Checking that it worked
SELECT TOP 5 [Month], Month_Start
FROM Clean_Portfolio_Summary;

-- Fix NIM_Pct — some rows entered as % (e.g. 7.5 instead of 0.075)
ALTER TABLE Clean_Portfolio_Summary
ADD NIM_Pct_Clean DECIMAL(10,6);

UPDATE Clean_Portfolio_Summary
SET NIM_Pct_Clean =
    CASE
        WHEN TRY_CAST(NIM_Pct AS DECIMAL(10,6)) > 1
            THEN TRY_CAST(NIM_Pct AS DECIMAL(10,6)) / 100
        ELSE TRY_CAST(NIM_Pct AS DECIMAL(10,6))
    END;

-- Checking that all values are between 0 and 1
SELECT MIN(NIM_Pct_Clean), MAX(NIM_Pct_Clean)
FROM Clean_Portfolio_Summary;

-- FINAL CHECK
SELECT TOP 10 *
FROM Clean_Portfolio_Summary;

-- LENDING PORTFOLIO ANALYSIS QUERIES
-- SECTION 1 — "ARE WE MAKING MONEY OR JUST ISSUING LOANS?
-- Portfolio size, yield, NIM, cost of risk

-- 1a: Total portfolio size and loan count
SELECT
    COUNT(*) AS Total_Loans,
    SUM(Principal_Amount) AS Total_Originated,
    SUM(Outstanding_Balance) AS Total_Outstanding,
    AVG(Interest_Rate_Clean) AS Avg_Interest_Rate
FROM Clean_Loan_Book;

-- 1b: Portfolio size and NIM trend over time(monthly)
SELECT Month_Start, Portfolio_Size, Disbursements, NIM_Pct_Clean AS Net_Interest_Margin, Cost_of_Risk,
	   NIM_Pct_Clean - Cost_of_Risk AS Risk_Adjusted_NIM
FROM Clean_Portfolio_Summary
ORDER BY Month_Start;

-- 1c: Portfolio breakdown by product type
SELECT Product_Type, COUNT(*) AS Loan_Count, SUM(Outstanding_Balance) AS Total_Outstanding,
	ROUND(AVG(Interest_Rate_Clean) * 100, 2) AS Avg_Rate_Pct,
    ROUND(SUM(Outstanding_Balance) * 100.0 / SUM(SUM(Outstanding_Balance)) OVER (), 2) AS Pct_of_Portfolio
FROM Clean_Loan_Book
GROUP BY Product_Type
ORDER BY Total_Outstanding DESC;

-- 1d: Portfolio breakdown by borrower segment
SELECT Borrower_Segment, COUNT(*) AS Loan_Count,
    SUM(Outstanding_Balance) AS Total_Outstanding,
    ROUND(AVG(Interest_Rate_Clean) * 100, 2) AS Avg_Rate_Pct
FROM Clean_Loan_Book
GROUP BY Borrower_Segment
ORDER BY Total_Outstanding DESC;

-- SECTION 2 — "HOW RISKY IS THIS PORTFOLIO?"
-- PAR30, PAR90, NPL ratio, default rates

-- 2a: Overall PAR30 and PAR90
SELECT SUM(Outstanding_Balance) AS Total_Portfolio,
	SUM(CASE WHEN Loan_Status IN ('30-59 DPD','60-89 DPD','90+ DPD','Written Off')
             THEN Outstanding_Balance ELSE 0 END) AS PAR30_Balance,
	SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
             THEN Outstanding_Balance ELSE 0 END) AS PAR90_Balance,
	ROUND(SUM(CASE WHEN Loan_Status IN ('30-59 DPD','60-89 DPD','90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS PAR30_Pct,
	ROUND(SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS PAR90_Pct
FROM Clean_Loan_Book;

-- 2b: PAR by region
SELECT Region, COUNT(*) AS Total_Loans,
    SUM(Outstanding_Balance) AS Total_Outstanding,
    ROUND(SUM(CASE WHEN Loan_Status IN ('30-59 DPD','60-89 DPD','90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS PAR30_Pct,
    ROUND(SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS PAR90_Pct
FROM Clean_Loan_Book
GROUP BY Region
ORDER BY PAR30_Pct DESC;

-- 2c: PAR by product type
SELECT Product_Type, COUNT(*) AS Total_Loans,
    ROUND(SUM(CASE WHEN Loan_Status IN ('30-59 DPD','60-89 DPD','90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS PAR30_Pct,
    ROUND(SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS PAR90_Pct
FROM Clean_Loan_Book
GROUP BY Product_Type
ORDER BY PAR30_Pct DESC;

-- 2d: NPL ratio and default rate by borrower segment
SELECT Borrower_Segment, COUNT(*) AS Total_Loans,
    SUM(CASE WHEN Loan_Status = 'Written Off'
             THEN 1 ELSE 0 END) AS Written_Off_Count,
    ROUND(SUM(CASE WHEN Loan_Status = 'Written Off'
                 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Default_Rate_Pct,
    ROUND(SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS NPL_Ratio_Pct
FROM Clean_Loan_Book
GROUP BY Borrower_Segment
ORDER BY Default_Rate_Pct DESC;

-- 2e: Vintage analysis — default rate by disbursement quarter
-- Which loan cohorts are performing badly?
SELECT DATEFROMPARTS(YEAR(Disbursement_Date_Clean), (DATEPART(QUARTER, Disbursement_Date_Clean) - 1) * 3 + 1, 1)                                           AS vintage_quarter,
    COUNT(*) AS Loans_Originated,
    SUM(Principal_Amount) AS Volume_Originated,
    SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
             THEN 1 ELSE 0 END) AS Defaulted,
    ROUND(SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
                 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Default_Rate_Pct
FROM Clean_Loan_Book
WHERE Disbursement_Date_Clean IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(Disbursement_Date_Clean), (DATEPART(QUARTER, Disbursement_Date_Clean) - 1) * 3 + 1, 1)
ORDER BY Vintage_Quarter;

-- SECTION 3 — "ARE OUR COLLECTIONS STRATEGIES WORKING?"
-- Roll rates, cure rates, recovery efficiency
-- 3a: DPD bucket distribution — where is the portfolio sitting?
SELECT
    CASE
        WHEN Days_Past_Due = 0 THEN '0 - Current'
        WHEN Days_Past_Due BETWEEN 1  AND 29 THEN '1-29 DPD'
        WHEN Days_Past_Due BETWEEN 30 AND 59 THEN '30-59 DPD'
        WHEN Days_Past_Due BETWEEN 60 AND 89 THEN '60-89 DPD'
        WHEN Days_Past_Due BETWEEN 90 AND 179 THEN '90-179 DPD'
        WHEN Days_Past_Due >= 180 THEN '180+ DPD'
    END AS DPD_Bucket,
    COUNT(*) AS Loan_Count,
    SUM(Outstanding_Balance) AS Outstanding_Balance,
    ROUND(
        SUM(Outstanding_Balance) * 100.0
        / SUM(SUM(Outstanding_Balance)) OVER (), 2) AS Pct_of_Portfolio
FROM Clean_Loan_Book
GROUP BY
    CASE
        WHEN Days_Past_Due = 0 THEN '0 - Current'
        WHEN Days_Past_Due BETWEEN 1  AND 29 THEN '1-29 DPD'
        WHEN Days_Past_Due BETWEEN 30 AND 59 THEN '30-59 DPD'
        WHEN Days_Past_Due BETWEEN 60 AND 89 THEN '60-89 DPD'
        WHEN Days_Past_Due BETWEEN 90 AND 179 THEN '90-179 DPD'
        WHEN Days_Past_Due >= 180 THEN '180+ DPD'
    END
ORDER BY MIN(Days_Past_Due);

-- 3b: Cure rate by collections action type
-- Which actions actually bring customers back to current?
SELECT Action_Type, COUNT(*) AS Times_Used,
    SUM(CASE WHEN cured = 1 THEN 1 ELSE 0 END) AS Times_Cured,
    ROUND(SUM(CASE WHEN cured = 1 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Cure_Rate_Pct
FROM Clean_Collections_Log
GROUP BY Action_Type
ORDER BY Cure_Rate_Pct DESC;

-- 3c: Recovery efficiency by action type
-- Are we spending more to collect than we recover?
SELECT Action_Type, ROUND(SUM(Amount_Recovered), 2) AS Total_Recovered,
    ROUND(SUM(Recovery_Cost), 2) AS Total_Cost,
    ROUND(SUM(Amount_Recovered) / NULLIF(SUM(Recovery_Cost), 0), 2) AS Recovery_ROI
    -- ROI > 1 means we recovered more than we spent. Good.
    -- ROI < 1 means collections cost more than we got back. Bad.
FROM Clean_Collections_Log
GROUP BY Action_Type
ORDER BY Recovery_ROI DESC;

-- 3d: Payment behaviour — how many customers are paying in full vs partially?
SELECT Payment_Status, COUNT(*) AS Payment_Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS Pct_of_Payments,
    ROUND(AVG(
        CASE WHEN ISNUMERIC(Scheduled_Amount) = 1
                  AND ISNUMERIC(Actual_Payment) = 1
                  AND TRY_CAST(Scheduled_Amount AS DECIMAL(18,2)) > 0
             THEN TRY_CAST(Actual_Payment AS DECIMAL(18,2))
                  / TRY_CAST(Scheduled_Amount AS DECIMAL(18,2)) * 100
             ELSE NULL
        END
    ), 2) AS Avg_Coverage_Pct
FROM Clean_Repayment_History
GROUP BY Payment_Status
ORDER BY payment_count DESC;

-- 3e: Collections performance by agent
-- Who are your best collectors?
SELECT Agent_ID,
    COUNT(*) AS Total_Actions,
    SUM(CASE WHEN Cured = 1 THEN 1 ELSE 0 END) AS Cures,
    ROUND(SUM(CASE WHEN Cured = 1 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Cure_Rate_Pct,
    ROUND(SUM(Amount_Recovered), 2) AS Total_Recovered,
    ROUND(SUM(Recovery_Cost), 2) AS Total_Cost
FROM Clean_Collections_Log
GROUP BY Agent_ID
ORDER BY Total_Recovered DESC;

-- SECTION 4 — "ARE WE GROWING INTELLIGENTLY?"
-- Disbursement growth, new vs repeat borrowers, product profitability
-- 4a: Monthly disbursement trend
SELECT Month_Start, Disbursements, New_Borrowers, Repeat_Borrowers, Active_Borrowers,
    ROUND(Repeat_Borrowers * 100.0 / NULLIF(Active_Borrowers, 0), 2) AS Repeat_Borrower_Ratio_Pct
FROM Clean_Portfolio_Summary
ORDER BY Month_Start;

-- 4b: Loan disbursements by year and product type
SELECT YEAR(Disbursement_Date_Clean) AS Disbursement_Year, Product_Type,
    COUNT(*) AS Loans_Issued,
    SUM(Principal_Amount) AS Total_Disbursed
FROM Clean_Loan_Book
WHERE Disbursement_Date_Clean IS NOT NULL
GROUP BY YEAR(Disbursement_Date_Clean), Product_Type
ORDER BY Disbursement_Year, Total_Disbursed DESC;

-- 4c: Geographic growth — which regions are growing fastest?
SELECT Region, YEAR(Disbursement_Date_Clean) AS Yr,
    COUNT(*) AS Loans_Issued,
    SUM(Principal_Amount) AS Total_Disbursed
FROM Clean_Loan_Book
WHERE Disbursement_Date_Clean IS NOT NULL
GROUP BY Region, YEAR(Disbursement_Date_Clean)
ORDER BY Region, Yr;

-- SECTION 5 — "WHAT EARLY WARNING SIGNALS ARE EMERGING?"
-- Payment delays, stress by segment, time to first delinquency

-- 5a: Average days past due by region and product
-- Rising averages = stress building in those segments
SELECT Region, Product_Type,
    COUNT(*) AS Loan_Count,
    ROUND(AVG(CAST(Days_Past_Due AS DECIMAL)), 1) AS Avg_Days_Past_Due,
    MAX(Days_Past_Due) AS Max_Days_Past_Due
FROM Clean_Loan_Book
WHERE Loan_Status != 'Current'
GROUP BY Region, Product_Type
ORDER BY Avg_Days_Past_Due DESC;

-- 5b: Monthly PAR30 and PAR90 trend from the summary table
--     A rising PAR trend is your clearest early warning signal
SELECT Month_Start, PAR30_Pct, PAR90_Pct, NPL_Ratio,
    -- Flag months where PAR30 jumped more than 2 percentage points
    CASE
        WHEN PAR30_Pct - LAG(PAR30_Pct) OVER (ORDER BY Month_Start) > 0.02
        THEN 'WARNING'
        ELSE 'OK'
    END AS PAR30_Spike_Flag
FROM Clean_Portfolio_Summary
ORDER BY Month_Start;

-- 5c: Late payment trend — are customers paying later over time?
SELECT YEAR(Payment_Date_Clean) AS Payment_Year,
    MONTH(Payment_Date_Clean) AS Payment_Month,
    ROUND(AVG(CAST(Days_Late AS DECIMAL)), 1) AS Avg_Days_Late,
    COUNT(*) AS Payment_Count,
    SUM(CASE WHEN Days_Late > 0 THEN 1 ELSE 0 END) AS Late_Payments,
    ROUND(SUM(CASE WHEN Days_Late > 0 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Late_Payment_Rate_Pct
FROM Clean_Repayment_History
WHERE Payment_Date_Clean IS NOT NULL
GROUP BY YEAR(Payment_Date_Clean), MONTH(Payment_Date_Clean)
ORDER BY Payment_Year, Payment_Month;

-- 5d: Borrower segments showing the most stress
SELECT Borrower_Segment,
    COUNT(*) AS Total_Loans,
    ROUND(AVG(CAST(Days_Past_Due AS DECIMAL)), 1) AS Avg_DPD,
    SUM(CASE WHEN Loan_Status IN ('60-89 DPD','90+ DPD','Written Off')
             THEN 1 ELSE 0 END) AS Seriously_Delinquent,
    ROUND(SUM(CASE WHEN Loan_Status IN ('60-89 DPD','90+ DPD','Written Off')
                 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Serious_Delinquency_Rate_Pct
FROM Clean_Loan_Book
GROUP BY Borrower_Segment
ORDER BY Serious_Delinquency_Rate_Pct DESC;

-- SECTION 6 — "IS THE PORTFOLIO RESILIENT?"
-- Concentration risk, collateral coverage, write-offs vs recoveries
SELECT Region, COUNT(*) AS Loan_Count,
    SUM(Outstanding_Balance) AS Outstanding,
    ROUND(SUM(Outstanding_Balance) * 100.0
        / SUM(SUM(Outstanding_Balance)) OVER (), 2) AS Pct_of_Portfolio
FROM Clean_Loan_Book
GROUP BY Region
ORDER BY Pct_of_Portfolio DESC;

-- 6b: Collateral coverage ratio
-- How much of the at-risk portfolio is covered by collateral?
SELECT ROUND(SUM(CASE WHEN Collateral_Value IS NOT NULL
                 THEN Outstanding_Balance ELSE 0 END)
        / SUM(Outstanding_Balance) * 100, 2) AS Pct_Portfolio_Secured,
    ROUND(SUM(Collateral_Value) / NULLIF(SUM(Outstanding_Balance), 0), 2) AS Collateral_Coverage_Ratio
    -- A ratio > 1 means collateral exceeds the loan book. Healthy.
FROM Clean_Loan_Book;

-- 6c: Write-offs vs recoveries over time
SELECT Month_Start, Write_Offs, Recoveries,
    ROUND(Recoveries * 100.0 / NULLIF(Write_Offs, 0), 2) AS Recovery_Rate_Pct
FROM Clean_Portfolio_Summary
ORDER BY Month_Start;

-- 6d: Loan officer risk — which officers have the highest default rates?
--  Useful for spotting credit standard issues at origination
SELECT Loan_Officer_ID, COUNT(*) AS Loans_Issued,
    SUM(Principal_Amount) AS Total_Disbursed,
    SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
             THEN 1 ELSE 0 END) AS High_Risk_Loans,
    ROUND(SUM(CASE WHEN Loan_Status IN ('90+ DPD','Written Off')
                 THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2) AS Default_Rate_Pct
FROM Clean_Loan_Book
GROUP BY Loan_Officer_ID
ORDER BY Default_Rate_Pct DESC;











