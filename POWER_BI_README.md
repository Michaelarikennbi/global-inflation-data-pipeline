##  DAX Architecture & Rationale

Building enterprise-grade financial dashboards requires moving past simple aggregations into advanced statistical modeling. The engineering logic behind the custom DAX expressions implemented in this model includes:

### 1. State-Preserving Inflation Tracking via Variables (`Current YOY Inflation`)
* **Technical Method:** Leveraged local evaluation storage (`VAR` / `RETURN`) alongside time-series slicing execution (`MAX`).
* **Business Rationale:** Using variables locks the calculation state in memory for the duration of the query. Instead of forcing the Power BI VertiPaq engine to repeatedly compute the `LatestYear` for every row evaluation, the value is calculated once and reused. This drastically optimizes dashboard responsiveness and cross-filtering speed, while the `DIVIDE` function seamlessly handles potential zero-record errors by outputting a clean blank instead of crashing.

### 2. Context-Agnostic Baseline Evaluation (`Prior_Year_CPI`)
* **Technical Method:** Modified database evaluation contexts using `CALCULATE` paired with an overriding `FILTER(ALL(...))` array matrix.
* **Business Rationale:** In standard reporting, clicking a specific calendar year would instantly truncate the data model's view to *only* that year, making comparative trend analysis impossible. By applying `ALL('CPI_TABLE'[Year_num])`, we programmatically force the engine to step outside the user's active filter selection, look backward exactly one year (`LatestYear - 1`), and retrieve historical baselines on the fly.

### 3. Iterative Economic Risk & Dispersion Tracking (`Historical Peak Shock` & `Sector Volatility Index`)
* **Technical Method:** Deployed advanced X-system iterators (`MAXX` and `STDEVX.P`) running over multi-row historical dimensional arrays.
* **Business Rationale:** A simple average completely flattens out economic reality—it fails to tell stakeholders how unstable an asset class is. Implementing `STDEVX.P` measures the exact statistical variance (Standard Deviation) of price swings across years, providing an institutional-grade **Volatility Index** to isolate which economic sectors are highly unstable. Meanwhile, `MAXX` scans the entire chronological timeline to flag the single worst historical price shock, ensuring risk teams know the historical ceiling of market stress.
