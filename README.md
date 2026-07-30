# Customer Segmentation Using RFM Analysis and K-Means Clustering

**Evidence from an Online Retail Dataset**

Independent Research Project 1 — Juliana Agyapong, M.S. Marketing Analytics, Illinois Institute of Technology

📄 **[Read the full report (PDF)](Customer_Segmentation_RFM_Research_Report.pdf)**

📊 **[View the research presentation (PowerPoint)](Customer_Segmentation_Presentation.pptx)**

## Overview

This project investigates whether purchase frequency and monetary value represent a single underlying dimension of customer purchasing behavior, or two distinct dimensions that together reveal meaningful customer segments. Using transaction data from a UK-based online retailer, RFM (Recency, Frequency, Monetary) variables were constructed for 4,338 customers and analyzed using Spearman correlation, k-means clustering, silhouette validation, and principal component analysis.

## Key Findings

- Frequency and Monetary value ar
- e strongly correlated overall (ρ = 0.807, p < .001)
- However, k-means clustering (k = 4) identifies four behaviorally distinct customer segments — rare buyers, regular repeat customers, loyal high-value customers, and extreme outliers — that a single-dimension view would obscure
- PCA shows these segments exist along a continuous behavioral spectrum rather than as sharply bounded groups
- Together, these results suggest that while Frequency and Monetary value move together on average, analyzing them jointly reveals customer heterogeneity relevant to targeted marketing and retention strategies

## Repository Contents

| File | Description |
|---|---|
| `Project1_Final_Report.pdf` | Full research report (Introduction, Literature Review, Methodology, Results, Discussion, Conclusion, References, Appendix) |
| `analysis.R` | Complete R script: data cleaning, RFM construction, correlation analysis, k-means clustering, silhouette validation, and PCA |
| `figures/` | All figures generated during analysis (elbow plot, cluster plot, PCA plot, log-transformed distribution) |

## Data

This project uses the **Online Retail II** dataset (UK-based online gift retailer, 2009–2011 transactions), publicly available via the UCI Machine Learning Repository / Kaggle. The dataset is not included in this repository; download it and place it at `data/online_retail_II.csv` to reproduce the analysis.

## Methods

- **Data cleaning:** removal of cancelled orders, non-positive prices, and missing Customer IDs
- **RFM construction:** Recency, Frequency, and Monetary value computed per customer
- **Correlation:** Spearman rank correlation (chosen for robustness to skew and outliers)
- **Clustering:** k-means (k = 4), selected via the elbow method and validated via silhouette analysis (k = 2–10)
- **Dimensionality reduction:** PCA on Recency, Frequency, and log-transformed Monetary value

## Reproducibility

R session info (package versions used for this analysis) is included in the Appendix of the full report.

---

*This is Project 1 of a five-project consumer behavior research portfolio, developed to support PhD applications in Marketing (Consumer Behavior) for Fall 2027 entry.*
