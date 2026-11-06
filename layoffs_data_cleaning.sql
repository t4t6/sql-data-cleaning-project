/*
Project: Layoffs Data Cleaning
Database: MySQL 8.0+
Purpose:
  1. Create a working copy of the raw layoffs table.
  2. Remove duplicate records.
  3. Standardize text and date values.
  4. Fill missing industry values where a matching company record exists.
  5. Remove rows with no layoff figures.
  6. Run final data-quality checks.

IMPORTANT:
- This script expects an existing table named `layoffs`.
- It does not modify the original `layoffs` table.
- It drops and recreates `layoffs_staging` and `layoffs_staging2`.
- Run it in the database that contains your raw `layoffs` table.
*/

-- ---------------------------------------------------------
-- 0. Create a fresh staging copy of the raw data
-- ---------------------------------------------------------

DROP TABLE IF EXISTS layoffs_staging2;
DROP TABLE IF EXISTS layoffs_staging;

CREATE TABLE layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;


-- ---------------------------------------------------------
-- 1. Identify and remove duplicate records
-- ---------------------------------------------------------
-- A duplicate is defined by matching values across all
-- business columns in this dataset.

CREATE TABLE layoffs_staging2 AS
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY
            company,
            location,
            industry,
            total_laid_off,
            percentage_laid_off,
            `date`,
            stage,
            country,
            funds_raised_millions
        ORDER BY company
    ) AS row_num
FROM layoffs_staging;

-- Review duplicate rows before deleting them.
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Keep the first occurrence of each duplicate group.
DELETE FROM layoffs_staging2
WHERE row_num > 1;


-- ---------------------------------------------------------
-- 2. Standardize text values
-- ---------------------------------------------------------

-- Remove leading and trailing spaces from company names.
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Convert blank industry values to NULL.
UPDATE layoffs_staging2
SET industry = NULLIF(TRIM(industry), '');

-- Standardize Crypto industry variations.
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Remove the trailing period from United States country values.
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM TRIM(country))
WHERE country LIKE 'United States%';


-- ---------------------------------------------------------
-- 3. Standardize the date column
-- ---------------------------------------------------------
-- The raw dataset stores dates as text in MM/DD/YYYY format.

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- ---------------------------------------------------------
-- 4. Populate missing industry values where possible
-- ---------------------------------------------------------
-- Use another non-NULL industry value for the same company.
-- Companies with no known industry remain NULL.

UPDATE layoffs_staging2 AS target
JOIN (
    SELECT
        company,
        MAX(industry) AS industry
    FROM layoffs_staging2
    WHERE industry IS NOT NULL
    GROUP BY company
) AS source
    ON target.company = source.company
SET target.industry = source.industry
WHERE target.industry IS NULL;


-- ---------------------------------------------------------
-- 5. Remove rows with no layoff figures
-- ---------------------------------------------------------
-- These rows contain neither a total layoff count nor
-- a percentage, so they are not useful for layoff analysis.

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- ---------------------------------------------------------
-- 6. Final data-quality checks
-- ---------------------------------------------------------

-- Check the cleaned dataset.
SELECT *
FROM layoffs_staging2
ORDER BY `date`, company;

-- Check for remaining duplicate groups.
SELECT
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    country,
    funds_raised_millions,
    COUNT(*) AS duplicate_count
FROM layoffs_staging2
GROUP BY
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    country,
    funds_raised_millions
HAVING COUNT(*) > 1;

-- Check missing industry values.
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- Check rows that still have no layoff figures.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Compare raw and cleaned row counts.
SELECT 'Raw data' AS dataset, COUNT(*) AS row_count
FROM layoffs
UNION ALL
SELECT 'Cleaned data' AS dataset, COUNT(*) AS row_count
FROM layoffs_staging2;

-- The cleaned table is `layoffs_staging2`.
-- Keep it for the exploratory data analysis project.
