# Layoffs Data Cleaning (MySQL)

## Project Overview
This project cleans a company-layoffs dataset using MySQL. The goal is to prepare a consistent, analysis-ready table while preserving the original raw data.

## Objectives
- Create staging tables so the raw dataset remains unchanged.
- Identify and remove duplicate records.
- Standardize company, industry, country, and date values.
- Fill missing industry values when another record for the same company provides the information.
- Remove records that contain neither a total layoff count nor a layoff percentage.
- Run validation queries on the cleaned dataset.

## Tools
- MySQL 8.0+
- MySQL Workbench (or another MySQL client)

## Files
- `layoffs_data_cleaning.sql` — complete SQL cleaning workflow.

## Dataset Requirements
Before running the script:
1. Create or select a MySQL database.
2. Import the raw dataset into a table named `layoffs`.
3. Confirm that the table contains these columns:

`company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`

The script expects `funds_raised_millions` (plural) and a raw date format of `MM/DD/YYYY`.

## How to Run
1. Open MySQL Workbench and connect to your MySQL server.
2. Select the database containing the raw `layoffs` table.
3. Open `layoffs_data_cleaning.sql`.
4. Execute the script.
5. Review the validation queries at the end.
6. Use `layoffs_staging2` as the cleaned table for further analysis.

> **Warning:** The script drops and recreates `layoffs_staging` and `layoffs_staging2` each time it runs. It does not drop or update the original `layoffs` table. Back up your work before running it if you already have important tables with those staging names.

## Data Cleaning Steps

### 1. Staging
Creates a working copy of the raw table so the source data is preserved.

### 2. Duplicate Removal
Uses `ROW_NUMBER()` with a partition over the dataset's business columns to identify duplicate records, then removes rows numbered greater than 1.

### 3. Standardization
- Trims extra spaces from company names.
- Converts blank industry values to `NULL`.
- Standardizes industry values beginning with `Crypto` to `Crypto`.
- Removes the trailing period from United States country values.

### 4. Date Conversion
Converts the text date from `MM/DD/YYYY` into MySQL's `DATE` data type.

### 5. Missing Industry Values
Fills a missing industry value using a non-NULL industry value from another row for the same company, where available.

### 6. Removing Unusable Rows
Removes rows where both `total_laid_off` and `percentage_laid_off` are `NULL`.

### 7. Validation
Checks for remaining duplicates, missing industries, unusable layoff rows, and compares raw versus cleaned row counts.

## Key SQL Concepts Demonstrated
- `CREATE TABLE ... LIKE`
- `INSERT INTO ... SELECT`
- Common Table Expressions / window-function concepts
- `ROW_NUMBER()` and `PARTITION BY`
- `UPDATE` with joins
- `TRIM()`, `NULLIF()`, and `STR_TO_DATE()`
- `ALTER TABLE`
- `DELETE`
- `GROUP BY` and `HAVING`

## Notes and Limitations
- Duplicate detection is based on equality across the listed dataset columns. If two genuinely separate events have identical values in every listed column, this method will treat one as a duplicate.
- The script assumes MySQL 8.0+ for window functions.
- The script assumes the source column is named `funds_raised_millions`. If your imported table uses a different spelling, update the script to match the actual column name.
- The date conversion assumes the raw date format is `MM/DD/YYYY`.

## Next Step
Use the cleaned `layoffs_staging2` table for exploratory data analysis, visualization, and business insights.
