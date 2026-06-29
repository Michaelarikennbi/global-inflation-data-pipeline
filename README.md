 global-inflation-data-pipeline
An end-to-end T-SQL database normalization and data engineering pipeline analyzing 26 years of global CPI metrics

Global Consumer Price Index (CPI) Data Engineering Pipeline

An end-to-end relational data warehousing and optimization pipeline built using T-SQL (SQL Server). This project ingests denormalized wide-format global inflation data from the United Nations, executes key programmatic text and structural transformations, and outputs a highly optimized Star Schema schema optimized for enterprise analytics and business intelligence.

 Data Source & Provenance
The raw records utilized in this data infrastructure are published by the **Food and Agriculture Organization (FAO) of the United Nations**. The dataset maps historical global consumer price metrics, food inflation indicators, and index tracking benchmarks from 2000 to 2025.

Official Data Portal:[FAOSTAT Consumer Price Indices Portal](https://www.fao.org/faostat/en/#data/CP/metadata)

Raw Files Processed:
   `ConsumerPriceIndices_E_All_Data.csv` (Primary comprehensive wide-matrix data)
   `ConsumerPriceIndices_E_All_Data_NOFLAG.csv` (Primary metric numeric matrix)
   `ConsumerPriceIndices_E_AreaCodes.csv` (Geographical entity metadata)
   `ConsumerPriceIndices_E_ItemCodes.csv` (Commodity and classification metadata)
   `ConsumerPriceIndices_E_Elements.csv` (Analytical metrics metadata)
   `ConsumerPriceIndices_E_Flags.csv` (Data recording quality status metadata)


Data Architecture & Cleaning Rationale

Raw source data rarely arrives structured for high-performance indexing or immediate business visualization. To transform these raw multi-column arrays into a production-ready relational data warehouse, the assets passed through a multi-phase lifecycle inside SQL Server. 

1. Staging Layer Architecture (Risk Mitigation)
*Technical Action*: Initialized empty replica table schemas using conditional logic (`WHERE 1=0`) to isolate tables (`CPI_STAGING`, `AreaCodes_staging`, `NOFLAG_staging`, etc.) before bulk inserting raw CSV records.
*Business Rationale*: Modifying production source tables directly is a dangerous architectural anti-pattern. If a data transformation contains a logical error or a destructive `UPDATE` statement executes without explicit boundaries, underlying historical records can be permanently corrupted. Utilizing an isolated staging layer acting as temporary engineering "scaffolding" ensures all raw mutations happen safely without impacting data integrity.

2. Text Normalization & Integrity Enforcement
*Technical Action*: Deployed string cleansing operations (`REPLACE`, `TRIM`) to systematically strip out syntax punctuation anomalies (such as raw escaped single quotes `'''` found in `M49_CODE` and trailing semicolons in commodity item details). Handled descriptive text misalignments via wildcard string matching (`LIKE '%land Islands%'`).
*Business Rationale*: Dirty syntax punctuation characters interfere with database matching joins, corrupt automated data pipelines, and break string grouping mechanisms in reporting tools (Power BI/Tableau). Enforcing absolute text consistency via `TRIM` ensures that categories like `"Food"` and `"Food "` are not indexed as separate operational entries during metric aggregations.

3. Structural Transformation (Matrix Unpivoting)
*Technical Action*:Re-engineered the core schema from a wide table format (where historical years `Y2000` through `Y2025` were stored as 26 independent columns) into a normalized, vertical time-series row format via a T-SQL `UNPIVOT` execution engine.
*Business Rationale*: Wide database arrays are highly non-scalable. If a new calendar year of records (e.g., 2026) is introduced into a wide framework, the physical database schema must be altered, causing upstream queries, views, and dashboards to fail. By unpivoting the matrix into a long vertical architecture, new time periods append naturally downward as rows. The infrastructure becomes inherently scalable, requiring zero maintenance when fresh data arrives.

4. Mathematical Date Derivation & Precision
*Technical Action*:Extracted embedded timeline metadata integers using algebraic subtraction `([Months_code] - 7000)` combined with `DATEFROMPARTS()` to instantiate a true, standardized temporal variable (`Reference_Date`). Wrapped values in an explicit `TRY_CAST` to a `DECIMAL(18,6)` to secure high-precision price data.
*Business Rationale*: The raw United Nations file lacked an explicit, operational date field, storing month names as encoded tracking numbers. Computing a native database `DATE` field unlocks advanced Time-Series processing capabilities in SQL and native Time Intelligence features in BI layers (such as rolling Year-over-Year inflation rates, moving averages, and cumulative index trend lines).

5. Relational Star Schema Realization
*Technical Action*: Extracted structural attributes to construct specialized dimension lookup entities (`Dimension_Areas`, `Dimension_Items`, `Dimension_Elements`). Enforced relational architecture by assigning strict Primary Keys and mapping Foreign Key constraints directly back to the centralized `CPI_Production` fact table. Purged intermediate staging environments (`DROP TABLE`) upon pipeline completion to optimize local data warehouse storage.
*Business Rationale*:Transitioning a flat flat-file matrix into a formalized relational Star Schema represents the industry-standard design for analytical performance. By implementing solid primary and foreign key constraints, data redundancy is minimized, analytical index querying speeds are maximized, and downstream BI platforms map table boundaries automatically without complex layout configurations.


