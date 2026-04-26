## SQL Queries
Key queries used in this project:

### Data Cleaning
```sql
CREATE OR REPLACE TABLE movie_analysis.movies_clean AS
SELECT * FROM movie_analysis.movies_metadata
WHERE 
  CAST(budget AS STRING) != '0'
  AND CAST(revenue AS STRING) != '0'
  AND budget IS NOT NULL
  AND revenue IS NOT NULL
  AND release_date IS NOT NULL
```

### Feature Engineering
```sql
CREATE OR REPLACE TABLE movie_analysis.movies_final AS
SELECT
  title,
  SAFE_CAST(budget AS FLOAT64) AS budget,
  SAFE_CAST(revenue AS FLOAT64) AS revenue,
  ROUND(SAFE_CAST(revenue AS FLOAT64) / 
    SAFE_CAST(budget AS FLOAT64), 2) AS roi,
  ROUND(SAFE_CAST(revenue AS FLOAT64) - 
    SAFE_CAST(budget AS FLOAT64), 0) AS profit,
  PARSE_DATE('%Y-%m-%d', release_date) AS release_date,
  EXTRACT(YEAR FROM PARSE_DATE('%Y-%m-%d', release_date)) AS release_year,
  EXTRACT(MONTH FROM PARSE_DATE('%Y-%m-%d', release_date)) AS release_month,
  SAFE_CAST(runtime AS FLOAT64) AS runtime,
  SAFE_CAST(vote_average AS FLOAT64) AS vote_average,
  original_language,
  production_companies,
  genres,
  CASE 
  WHEN SAFE_CAST(budget AS FLOAT64) < 5000000 THEN 'Micro Budget'
    WHEN SAFE_CAST(budget AS FLOAT64) < 50000000 THEN 'Mid Budget'
    WHEN SAFE_CAST(budget AS FLOAT64) < 150000000 THEN 'High Budget'
    ELSE 'Blockbuster Budget'
  END AS budget_tier,
  CASE
    WHEN ROUND(SAFE_CAST(revenue AS FLOAT64) / 
      SAFE_CAST(budget AS FLOAT64), 2) >= 3 THEN 'Highly Profitable'
    WHEN ROUND(SAFE_CAST(revenue AS FLOAT64) / 
      SAFE_CAST(budget AS FLOAT64), 2) >= 1 THEN 'Profitable'
    ELSE 'Loss Making'
  END AS profitability_category
FROM movie_analysis.movies_clean
WHERE SAFE_CAST(budget AS FLOAT64) > 10000
```

### Genre Parsing
```sql
CREATE OR REPLACE TABLE movie_analysis.genres_clean AS
SELECT
  title, budget, revenue, roi, profit,
  release_year, release_month, budget_tier,
  profitability_category, vote_average, popularity,
  TRIM(REGEXP_EXTRACT(genre_raw, r"'name': '([^']+)'")) AS genre
FROM movie_analysis.movies_final,
UNNEST(SPLIT(REGEXP_REPLACE(genres, r'^\[|\]$', ''), '},')) AS genre_raw
WHERE TRIM(REGEXP_EXTRACT(genre_raw, r"'name': '([^']+)'")) IS NOT NULL
AND TRIM(REGEXP_EXTRACT(genre_raw, r"'name': '([^']+)'")) != ''
```
### Production_company Parsing
```sql
CREATE OR REPLACE TABLE `axial-autonomy-478712-i3.movie_analysis.production_clean` AS
SELECT
  title,
  budget,
  revenue,
  roi,
  profit,
  release_year,
  release_month,
  budget_tier,
  profitability_category,
  vote_average,
  popularity,
  TRIM(REGEXP_EXTRACT(company_raw, r"'name': '([^']+)'")) AS production_company
FROM `axial-autonomy-478712-i3.movie_analysis.movies_final`,
UNNEST(SPLIT(REGEXP_REPLACE(production_companies, r'^\[|\]$', ''), '},')) AS company_raw
WHERE TRIM(REGEXP_EXTRACT(company_raw, r"'name': '([^']+)'")) IS NOT NULL
AND TRIM(REGEXP_EXTRACT(company_raw, r"'name': '([^']+)'")) != ''
```
