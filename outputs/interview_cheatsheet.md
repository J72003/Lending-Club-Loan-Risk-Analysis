# Interview Cheat Sheet — Banking Analytics Dashboard

---

## 60-second project summary

"I built an end-to-end SQL and Python pipeline on LendingClub's public loan dataset — about a million records covering 2015 to 2018. I loaded the raw data into SQLite, wrote three SQL queries to analyse default rates by credit grade, origination year, and loan purpose, and then wrote a product analyst readout with findings and A/B test hypotheses aimed at a product manager audience. The most interesting finding was that LendingClub's interest rate pricing actually inverts at grade D — they charge 17.93% on average but those loans default at 19.96%, which means the rate doesn't cover expected losses before you even account for operating costs. I also caught a data quality issue before publishing: the source file hit Excel's row limit and silently truncated all pre-2015 records, which would have made the recent vintages look like a genuine improvement in credit quality when it was actually just loan immaturity."

---

## The three findings as interview answers

**Finding 1 — Pricing model breakdown at grade D**

"The most actionable finding was about risk-based pricing. When I compared the average interest rate at each credit grade against the observed default rate, the spread turns negative starting at grade D. Grade A loans charge 6.93% and default at 3.41% — there's room there. But grade D loans charge 17.93% and default at 19.96%. That's a negative spread of over two percentage points before operating costs. It gets worse at grades E, F, and G. What that means in product terms is that every grade D-through-G loan the platform originates needs to be subsidised by profits from grade A and B borrowers to stay net positive. That's not obvious from looking at the rates alone — you have to put the two numbers next to each other."

**Finding 2 — Vintage immaturity bias in recent data**

"The trend data showed what looked like a dramatic improvement in credit quality from 2015 to 2018. Grade E default rates appeared to fall from 34% in 2015 down to 6.6% in 2018. My first instinct was that this reflected genuine underwriting improvement, but then I realised the 2018 loans were only one to two years old when the data was captured — and defaults on consumer loans typically accumulate between years two and four. So the low 2017 and 2018 rates aren't a signal of better credit quality, they're a measurement artifact. The 2015 vintage is the most seasoned and the most honest benchmark for what the tail risk actually looks like. I noted this in the readout so anyone reading it wouldn't take the apparent improvement at face value."

**Finding 3 — 60-month term multiplies default risk across every purpose**

"The third finding was about product structure rather than credit scoring. When I broke out default rates by loan term and stated purpose, 60-month loans defaulted at meaningfully higher rates than 36-month loans for every single purpose category — not just riskier ones. Small business on 60 months defaulted at 22%, versus 16.5% on 36 months. Debt consolidation went from 11.4% to 17.4%. The term extension alone is adding four to seven percentage points of default risk regardless of what the loan is for. That's a product design question, not just an underwriting question — it suggests the 60-month option is selecting for borrowers who are already more financially stretched."

---

## "Walk me through your SQL" — reference query 1

"I'll walk you through the grade-level query since that's the one with the most interesting result. The structure is simple: I'm selecting grade, counting all rows as total loans, summing the is_default flag to get total defaults, and then dividing to get the default rate as a percentage — rounded to two decimal places. I'm also computing average loan amount and average interest rate at each grade. The filter is just `WHERE grade IS NOT NULL`, and I'm ordering by grade ascending so you can read A through G in one scan.

What makes it interesting isn't the SQL — it's what you do with the output. The query returns seven rows, one per grade. I added a manual calculation alongside it: interest rate minus default rate at each tier. That's when the grade D inversion became visible. The SQL itself is straightforward; the analyst judgment is knowing to make that comparison and recognise what it means for the pricing model."

---

## "What would you do differently?"

"The biggest thing I'd change is the data pipeline. I was working with an Excel export from Kaggle, and it silently hit Excel's 1,048,575 row limit — which truncated all pre-2015 records without any warning. I caught it because the trend query only returned data starting in 2015, which didn't match the dataset's stated 2007–2018 coverage. But I only caught it after the fact.

In a production pipeline I'd never use Excel as an intermediate format for a dataset this size. I'd pull the raw CSV directly, validate the row count against the source before any transformation, and add an assertion in the pipeline script that fails loudly if the count falls below a threshold. I'd also add a data freshness check and a schema validation step so if the source format ever changed, the pipeline would error rather than silently produce wrong output. The core SQL and analysis logic I'm happy with — it's the ingestion and validation layer I'd harden."

---

## "What does this tell a product team?"

"The grade D finding has a direct product implication. If I'm presenting to a product manager, I'd frame it this way: right now, every grade D, E, F, and G loan you originate is being cross-subsidised by your grade A and B volume. That's a deliberate business decision you might be comfortable with — maybe you want the volume, or you believe recoveries offset the loss — but it should be an explicit decision, not an invisible one. The product team has three levers: raise rates at grades D and above to close the gap, tighten eligibility so fewer high-risk borrowers are approved, or accept the subsidy but cap exposure to those tiers so the A/B volume never falls below what's needed to stay net positive. What I can't tell you from this data is which lever is right — that depends on recovery rates, competitive dynamics, and investor return requirements that aren't in this dataset. But I can tell you the gap exists and roughly how large it is."

---

## Three follow-up questions and answers

**Q: "Your default rate for grade D is 19.96% — but not all defaults mean a total loss. What's the actual loss rate?"**

"That's exactly the right pushback, and it's the main limitation I called out in the readout. The dataset doesn't include recovery amounts — what the platform actually collects after a loan charges off through collections or sale of the debt. Industry recovery rates on consumer loans typically run 20–40 cents on the dollar, which would meaningfully change the economics. To get to a true expected loss rate you'd need: default rate × loss given default, where loss given default equals 1 minus the recovery rate. I don't have that number here. What I can say is that even with a 40% recovery rate, grade D's effective loss rate would be around 12% of principal, which still leaves the 17.93% rate with a thin cushion — and grades E through G would still be net negative."

**Q: "Why did you choose SQLite instead of running this directly in pandas?"**

"Two reasons. First, it makes the analysis reproducible for anyone on the team who knows SQL but not Python — they can open the database and run the queries directly without touching the notebook. Second, it forces a clean separation between the data transformation layer and the analysis layer. The notebook handles all the messy cleaning — parsing dates, building the is_default flag, dropping nulls — and the SQL queries work against a clean, structured table. That separation means if the source data changes, I update the pipeline in one place and all three queries automatically reflect the new data. If I'd done everything in pandas, the logic would be scattered across multiple places and harder to audit."

**Q: "How would you validate that your is_default flag is correct?"**

"I'd do three checks. First, I'd print value_counts() on loan_status before and after creating the flag to confirm every status string I intended to capture is captured and nothing unexpected is being labelled as default. I actually did this in the notebook — the output showed the full list of status categories in the raw data, including some edge cases like the 'Does not meet the credit policy' variants, which I included explicitly. Second, I'd check that is_default and is_paid are never both equal to 1 for the same row — they should be mutually exclusive. Third, I'd spot-check a sample of rows where is_default equals 1 and confirm the loan_status values look correct. The overall default rate came out at 12.32%, which is consistent with what LendingClub's published loss rates were during this period, so the flag logic appears sound."
