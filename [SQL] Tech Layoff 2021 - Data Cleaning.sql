-- SQL Project - Data Cleaning Project
-- Dataset https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- Step 0: Creating stagging table

CREATE TABLE layoffs_staging
LIKE layoffs;

-- Insert all data from original table to the new ones
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- now follow below JTBDs:
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary

-- JTBD 1: Check and Remove the duplicate value

-- First, review all data to quick check for duplicate value
SELECT *
FROM layoffs_staging;

SELECT *,
ROW_NUMBER() OVER(
  PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Using CTE to filter the duplicate value, which their value in num_row column is greater than 1

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
  PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,'date', stage, country, funds_raised_millions) AS row_num
  FROM layoffs_staging;
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


-- Create another table to delete the duplicate value

CREATE TABLE `layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` int,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num int
);

-- Insert the data to the new table had been created

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Delete the rows where the row_num value is greater than 1

DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- JTBD 2: Standardizing the Data

-- Issue 1: Redundant spacing in company column

SELECT DISTINCT (company)
FROM layoffs_staging2;

SELECT DISTINCT (TRIM (company))
FROM layoffs_staging2;

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Issue 2: Empty, null value, the same thing in the ‘industry’ column

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Check the issue for Location column
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Check the issue for Country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE location LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM (TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Issue 3: Date is text type

SELECT `date`,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE (`date`, '%m/%d/%Y')

-- Configure the data type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- JTBD 3: Null or blank value that we can fix

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = ' ')
AND t2.industry IS NOT NULL


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = ' ')
AND t2.industry IS NOT NULL


UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ' ';


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL
AND t2.industry IS NOT NULL


SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = ' ')
AND t2.industry IS NOT NULL

-- JTBD 4: Remove any columns and rows that aren’t necessary

DETELE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL


ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
