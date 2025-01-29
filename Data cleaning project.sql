-- Data Cleaning
drop database parks_and_recreation;
use layoffs_of_world;


SELECT * 
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the data
-- 3. Null Values / Blank values (see if we can populate)
-- 4. Remove Any columns or Rows

Create Table layoffs_staging
like layoffs;

select *
from layoffs_staging;

-- to avoid screwing the raw data and use a different table with same database
insert layoffs_staging
select *
from layoffs;


select *,
row_number() over (
partition by company,industry,total_laid_off,percentage_laid_off, 'date') as row_num
from layoffs_staging;

select *
from layoffs_staging
where company = 'Casper';

-- making partition every tables
with duplicate_cte as
(
select *,
row_number() over (
partition by company,location, industry,total_laid_off,percentage_laid_off, 'date',stage,
country, funds_raised_millions) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num >1;

-- removing duplicate that
with duplicate_cte as
(
select *,
row_number() over (
partition by company,location, industry,total_laid_off,percentage_laid_off, 'date',stage,
country, funds_raised_millions) as row_num
from layoffs_staging 
)
delete 
from duplicate_cte
where row_num >1;

-- creating a new table to make changes and delete the duplicate to be safe
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2
where row_num >1;

insert into layoffs_staging2
select *,
row_number() over (
partition by company,location, industry,total_laid_off,percentage_laid_off, 'date',stage,
country, funds_raised_millions) as row_num
from layoffs_staging 
;
-- inserted copy of all column and add one more row_num

-- now we gonna delete the dupilcate data from the column if the row num > 1
DELETE
from layoffs_staging2
where row_num > 1;

-- checking the work
select *
from layoffs_staging2;

-- 2) standardizing data = finding issuses in your data and fixing it
select company, trim(company)
from layoffs_staging2;

-- trimming the company to have even blank spaces
update layoffs_staging2
set company = TRIM(company);

-- rearranging industry by alphabetical order
select distinct industry
from layoffs_staging2
order by 1;

select *
from layoffs_staging2
where industry like 'crypto%';

-- updating all to crypto 
update layoffs_staging2
set industry = 'crypto'
where industry like 'crypto%';

-- checking the work
select distinct industry
from layoffs_staging2
;

-- cheching the error for the united states.
select distinct country
from layoffs_staging2
where country like 'united states%';

-- trailing means coming at the end (what is trailing ',' is 
select distinct country, trim( trailing '.' from country) 
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = trim( trailing '.' from country) 
where country like 'united states%';
-- this fixed the mistake in spelling with united state

-- if we time series exploritory data analyst the date in the data needs to re-arranged
select *
from layoffs_staging2;
-- right now date is in text type
select `date`,
-- we gonna have in fromat to day - month -years
str_to_date (`date`,'%m/%d/%Y') 
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date (`date`,'%m/%d/%Y') ;

-- double check the data
select `date`
from layoffs_staging2;

-- changing the data type of date from txt(datatype) to date(datatype)
alter table layoffs_staging2
modify column `date` date;

-- checking what column has null values
select* from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- checking what column has null values on industry
select *
 from layoffs_staging2
where industry is null or industry = ''; -- no space 'between' ('') it recognizes as space 

select *
from layoffs_staging2
where company = 'Airbnb'
;

-- we are missing data from some of industy type so we going to do a self-join with a 
-- condition where if the location and the company is the same the industry it will update it self
-- with same type of industry
select *
from layoffs_staging2  t1
join layoffs_staging2 t2
	on t1.company = t2.company
	and t1.location = t1.location
 where (t1.industry is null or t1.industry = '')
 and t2.industry is not null;
 
 -- translating to update (this doesnot work as the system didnot read the blankspace on data)
 update layoffs_staging2  t1
join layoffs_staging2 t2
	on t1.company = t2.company
	set t1.location = t1.location
 where (t1.industry is null or t1.industry = '')
 and t2.industry is not null;
 
 -- set the industry to null
 update layoffs_staging2  
 set industry = null
 where indutry = ''
 ;
 
  -- translating to update
 update layoffs_staging2  t1
join layoffs_staging2 t2
	on t1.company = t2.company
	set t1.location = t1.location
 where t1.industry is null 
 and t2.industry is not null;
 
 select *
 from layoffs_staging2
 where company like 'bally%';
 
  select *
 from layoffs_staging2;
 
 -- coming back to null values for total_laid_off & percentage_laid_off
 select* from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
-- most of the company don't have data and we might not be able to use those without data

-- we are gonna delete it as the data is empty and the data cannot be collected
Delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

alter table layoffs_staging2
drop column row_num;
-- removing the column (row_num) as it was only used for the detection of duplicates and 
-- standardrization of the table
  
