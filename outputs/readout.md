# Banking Loan Risk Analysis
## Product Analyst Readout

---

**The business question**

LendingClub's core product promise is that it can price credit risk accurately enough to offer competitive rates to borrowers while still generating returns for investors. But accurate pricing requires that the interest rate charged at each credit tier actually covers the losses produced by defaults at that tier. If it does not, the platform is either subsidising risky borrowers with profits from safer ones, or quietly destroying value at scale. This analysis asks a direct question: does LendingClub's grade-based pricing model hold up against observed default outcomes — and which products and customer segments are the most exposed?

---

**Data and method**

This analysis uses 1,048,563 LendingClub loan records originating between 2015 and 2018, drawn from the platform's publicly released accepted-loan dataset. The analytical approach is descriptive SQL aggregation: grouping loans by grade, origination year, loan term, and stated purpose to compute observed default rates, payoff rates, and average loan characteristics. What this analysis can tell us is where default risk is concentrated and whether interest rates appear proportionate to that risk. What it cannot tell us is whether the relationships are causal, what the recovery rate is on defaulted loans, or whether risk has shifted since 2018 — all of which would be required before acting on these findings in a live credit model.

---

**Data quality flag — source file truncation**

The source file (`accepted_2007_to_2018Q4.xlsx`) loaded exactly 1,048,575 rows — Excel's hard row limit. This is not a coincidence. The LendingClub dataset covers 2007–2018, but the trend analysis in Finding 2 only returns data from 2015 onward, strongly suggesting pre-2015 origination records were silently truncated during the Excel export. Any vintage comparison involving pre-2015 cohorts should be treated as incomplete. For a full analysis, the raw CSV from Kaggle is required. This limitation is flagged here rather than buried in an appendix because it materially affects the scope of Finding 2.

---

**Finding 1 — Interest rate pricing loses ground to default losses starting at grade D**

LendingClub's seven credit grades span a wide range of observed default rates: 3.41% at the top (grade A) rising to 38.25% at the bottom (grade G). The interest rate spread follows — 6.93% average rate at grade A, 29.01% at grade G — which looks like disciplined risk-based pricing on the surface. The problem emerges when you compare the two numbers directly. At grade C, the 13.87% average interest rate covers the 13.66% default rate by just 0.21 percentage points. At grade D, the math inverts: borrowers are charged 17.93% on average, but 19.96% of them default — a gap of over two percentage points where losses exceed the rate premium before accounting for any operating costs or recovery values. The gap widens at grade E (21.37% rate, 28.20% default rate), grade F (25.58% rate, 36.17% default rate), and grade G (29.01% rate, 38.25% default rate).

**Product implication:** The risk-based pricing model needs recalibration for grades D through G; until expected losses are fully priced in, every dollar originated in those tiers requires a subsidy from higher-grade volume to stay net positive.

---

**Finding 2 — 2015 was the worst default vintage in the dataset, and recent data is misleading**

*Note: due to source file truncation at Excel's row limit, this trend analysis covers 2015–2018 only; pre-2015 vintages — which would be the most fully seasoned — are absent from the dataset.*

Filtering to grades A through E across origination years 2015–2018 reveals a striking and counterintuitive pattern. Default rates peak sharply in 2015: grade E borrowers originated that year defaulted at 34.22%, grade D at 27.55%, grade C at 19.45%. By 2016, rates had declined modestly — grade E fell to 33.00%, grade D to 27.03%. Then 2017 and 2018 show a dramatic apparent improvement: grade E drops to 21.34% in 2017 and 6.62% in 2018; even grade D falls to 4.48% in 2018. This looks like a turnaround story — but it is not. Loans originated in 2017 and 2018 were only one to two years old when this dataset was captured, and defaults typically accumulate over years two through four of a loan's life. The low default rates for recent vintages are a maturation artifact, not a signal of improved credit quality. The 2015 vintage, fully seasoned, is the most honest benchmark for what the tail risk actually looks like.

**Product implication:** Use 2015 default rates — not 2017 or 2018 — as the stress-test input when modelling expected portfolio losses; any credit policy decision based on recent vintage rates will systematically underestimate risk.

---

**Finding 3 — 60-month small business loans are the highest-risk product combination in the portfolio**

Across every loan purpose, 60-month terms produce meaningfully higher default rates than 36-month terms on the same purpose. The starkest example is small business lending: 36-month small business loans default at 16.53%; the 60-month equivalent defaults at 22.15% — a 34% relative increase in default risk simply by extending the term. The 60-month small business combination also has the lowest payoff rate in the dataset at 24.56%, meaning fewer than 1 in 4 borrowers has fully repaid. At the other end of the spectrum, 36-month car loans (8.53% default, avg $8,138) and 36-month credit card refinancing loans (8.60% default, avg $13,595) are the safest combinations in the portfolio. The 60-month term consistently adds 4 to 7 percentage points of default risk across almost every purpose category — debt consolidation goes from 11.43% to 17.35%, credit cards from 8.60% to 14.13%, home improvement from 9.30% to 14.01%.

**Product implication:** Apply a 36-month maximum term restriction to small business loans and evaluate whether the 60-month term option for debt consolidation is generating enough incremental volume to justify a default rate that is 52% higher than the 36-month equivalent.

---

**Three A/B test hypotheses**

**Hypothesis 1 — Repricing grades D and E reduces net losses without destroying origination volume**

- **Hypothesis:** Raising offered interest rates at grade D and E will reduce the gap between rate and expected loss, improving net yield on those tiers without materially suppressing demand.
- **Test:** For grade D applicants, increase the minimum offered rate by 2.5 percentage points. For grade E, add a 12-month minimum employment tenure requirement that must be verified before approval. Run against a control group receiving the current offer.
- **Primary metric:** Risk-adjusted net yield on D/E originations — (interest collected − default losses) / outstanding balance, annualised.
- **Guardrail metric:** Total origination volume for grade D/E applicants. A drop greater than 15% would signal over-restriction requiring a re-calibration of the rate increase.

**Hypothesis 2 — Removing the 60-month option for small business loans reduces default rate without collapsing volume**

- **Hypothesis:** Most small business applicants who currently select a 60-month term would accept a 36-month term with a modestly higher monthly payment, and the resulting portfolio will default at a significantly lower rate.
- **Test:** For a randomly selected 50% of small business applicants, suppress the 60-month term option so they see only 36 months as the maximum. Measure outcomes against the control group who sees both options.
- **Primary metric:** 12-month default rate on new small business originations (target: below 18%, vs. current 22.15% on 60-month).
- **Guardrail metric:** Small business application completion rate and total origination volume — confirms applicants are not abandoning the application when the longer term is unavailable.

**Hypothesis 3 — Requiring income verification at grade C improves loan quality at the tier where pricing cushion has nearly disappeared**

- **Hypothesis:** Grade C borrowers with self-reported income that cannot be verified are disproportionately represented among defaults. Adding a verification step will screen out the riskiest applicants at this tier, where the interest rate covers defaults by only 0.21 percentage points.
- **Test:** Randomly require 50% of grade C applicants to submit a recent pay stub or tax document before final approval. Compare 24-month default rates between the verified and unverified cohorts.
- **Primary metric:** 24-month default rate for grade C originations in the verified treatment group vs. unverified control.
- **Guardrail metric:** Grade C application completion rate — ensures the friction does not cause excess dropout among creditworthy borrowers who would have performed well.

---

**North star metric**

**Risk-Adjusted Net Yield (RANY)**, defined as:

> (Total interest collected − Total default losses) ÷ Total outstanding loan balance, annualised as a percentage.

This is the right north star because it forces the product team to hold two things in tension simultaneously: origination growth and credit quality. A team optimising for volume alone will push into grade D–G loans and 60-month terms, growing the book while destroying unit economics. A team optimising for default rate alone can stop lending entirely and achieve 0% defaults — which is also wrong. RANY cannot be improved by either of those strategies. It goes up only when the portfolio generates more interest income than it loses to defaults on a per-dollar basis. Alternatives like approval rate, origination volume, or default rate in isolation all have obvious gaming vectors. RANY does not.

---

**Limitations**

- **This analysis is observational, not causal.** The correlation between credit grade and default rate reflects LendingClub's own scoring model inputs, not an independent signal. We cannot determine whether a different scoring or pricing system would produce better outcomes, or whether grade itself causes defaults vs. simply categorising borrowers who would have defaulted anyway.

- **All three hypotheses require randomised experiments to validate.** Without random assignment, any comparison between grade D and grade E outcomes, or between 36-month and 60-month borrowers, is confounded by self-selection: borrowers who choose 60-month terms or receive grade D ratings are systematically different from those who do not, in ways this data cannot fully control for.

- **Three material data gaps weaken the analysis.** First, the dataset appears truncated at 1,048,575 rows (Excel's row limit), which means pre-2015 origination data — the years most likely to be fully seasoned — is missing entirely. Second, loan age at the time of data capture is not available, making it impossible to produce a true vintage curve that controls for time-on-book when comparing default rates across origination years. Third, post-default recovery rates are absent: a 20% default rate with 70% average recovery is a very different business outcome from 20% default with 10% recovery, and any accurate pricing model requires both inputs.

- **Source file hit Excel's 1,048,575 row limit, truncating pre-2015 origination records.** A complete vintage analysis requires the raw CSV source.
