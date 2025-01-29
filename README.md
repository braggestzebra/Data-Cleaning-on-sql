Layoffs Data Cleaning Project

Overview

This project focuses on cleaning and preparing layoff data for further analysis. The steps involve removing duplicates, standardizing data, handling null values, and ensuring data integrity.

Database and Table Setup

Dropping and Using the Correct Database

drop database parks_and_recreation;
use layoffs_of_world;

Viewing the Layoffs Data

SELECT * FROM layoffs;

Data Cleaning Steps

1. Removing Duplicates

Create a staging table to avoid modifying raw data.

CREATE TABLE layoffs_staging LIKE layoffs;
INSERT INTO layoffs_staging SELECT * FROM layoffs;

Identify duplicate records:

WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;

Remove duplicates safely by creating another staging table:

CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  `date` TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
);
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

Delete duplicate records:

DELETE FROM layoffs_staging2 WHERE row_num > 1;

2. Standardizing Data

Trim unnecessary spaces from company names:

UPDATE layoffs_staging2 SET company = TRIM(company);

Standardize industry names (e.g., merging variations of 'crypto'):

UPDATE layoffs_staging2 SET industry = 'crypto' WHERE industry LIKE 'crypto%';

Fix inconsistent country names:

UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE country LIKE 'united states%';

3. Converting Date Format

Convert date column from text to proper date format:

UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;

4. Handling Null Values

Identify missing industry data and fill it using a self-join:

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

Remove records where both total_laid_off and percentage_laid_off are NULL:

DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

5. Final Cleanup

Drop the row_num column as it was only used for duplicate detection:

ALTER TABLE layoffs_staging2 DROP COLUMN row_num;

Summary

This project provides a structured approach to cleaning layoff data, ensuring accuracy and consistency before conducting any further analysis. By creating staging tables, handling null values, and standardizing entries, we ensure the dataset is reliable for use in business intelligence and data analytics applications.

Contributors

Bishal Shrestha


