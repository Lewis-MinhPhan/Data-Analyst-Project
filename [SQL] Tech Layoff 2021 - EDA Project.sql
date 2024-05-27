-- Looking arround the data
SELECT * 
FROM layoffs_staging2;


-- Looking at Percentage to see how big these layoffs were
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;


-- Which companies had 1 which is basically 100 percent of they company laid off
SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1;
-- these are mostly startups it looks like who all went out of business during this time


-- By ordering funcs_raised_millions, we can see how large some of the companies are that have laid off their entire workforce.
SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- Top 5 companies that have laid off the highest number of employees in a single layoff event?
SELECT company, total_laid_off
FROM layoffs_staging2
ORDER BY 2 DESC
LIMIT 5;


-- Top 10 companies with the highest total layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;


-- Top 10 locations with the highest total layoffs?
SELECT location, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;


-- Which countries have the highest total layoffs?
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;


-- Which years have the highest total layoffs?
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;


-- Which industries have the highest total layoffs?
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


-- Which stage have the highest total layoffs?
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- Top 3 companies with the highest total number of layoffs for each year
-- Using 2 CTEs
WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;


-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;


-- now use it in a CTE so we can query off of it
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;