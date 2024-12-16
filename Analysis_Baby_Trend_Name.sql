-- BABY  NAME TREND PROJECT 
USE baby_names_db;
-- MySQL 

-- 1. Track changes in popularity
-- Find the overall most popular girl and boy names and show how they have changed in popularity rankings over the years
SELECT * FROM names;
SELECT * FROM regions;

-- Most popular girl name
SELECT
	Name, 
    SUM(births) AS num_babies
FROM names
WHERE Gender = 'F'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1; -- Jessica

-- How 'Jessica' name have changed in popularity rankings over the years
WITH popularity_name AS (SELECT
	Year,
	Name, 
    SUM(births) AS num_babies, 
    ROW_NUMBER() OVER(PARTITION BY Year ORDER BY SUM(births) DESC) AS popular_name
FROM names
WHERE Gender = 'F'
GROUP BY 1,2)
SELECT 
	* 
FROM popularity_name
WHERE Name = 'Jessica'; -- It was the third ranking in 1980 and get most popular from 1981 - 1997, 1998 start dropped to the 8th and even to the 78th in 2009

-- Most popular boy name
SELECT
	Name, 
    SUM(births) AS num_babies
FROM names
WHERE Gender = 'M'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1; -- Michael

-- How 'Michael' name have changed in popularity rankings over the years
WITH popularity_name AS (SELECT
	Year,
	Name, 
    SUM(births) AS num_babies, 
    ROW_NUMBER() OVER(PARTITION BY Year ORDER BY SUM(births) DESC) AS popular_name
FROM names
WHERE Gender = 'M'
GROUP BY 1,2)
SELECT 
	* 
FROM popularity_name
WHERE Name = 'Michael'; -- Seem like Michael been always the popular name, always in the top 3


-- Find the names with the biggest jumps in popularity from the first year of the data set to the last year
WITH names_1980 AS( SELECT
						Year,
						Name, 
						SUM(births) AS num_babies, 
						ROW_NUMBER() OVER(PARTITION BY Year ORDER BY SUM(births) DESC) AS popular_name
					FROM names
					WHERE Year = 1980
					GROUP BY 1,2),
	names_2009 AS( SELECT
						Year,
						Name, 
						SUM(births) AS num_babies, 
						ROW_NUMBER() OVER(PARTITION BY Year ORDER BY SUM(births) DESC) AS popular_name
					FROM names
					WHERE Year = 2009
					GROUP BY 1,2)
SELECT t1.Year, t1.Name, t1.popular_name,
	   t2.Year, t2.Name, t2.popular_name, 
       CAST(t2.popular_name AS SIGNED) - CAST(t1.popular_name AS SIGNED) AS diff
FROM names_1980 t1 INNER JOIN names_2009 t2
	ON t2.Name = t1.Name 
ORDER BY diff; -- Aidan was the biggest jump from 1980 to 2009, from 5691 babies in 1980 down to 109 babies in 2009

-- 2. Compare popularity across decades
-- For each year, return the 3 most popular girl names and 3 most popular boy names
WITH ranking_name AS( SELECT 
						Year, 
						Name, 
						Gender,
						SUM(Births) AS num_babies,
						ROW_NUMBER() OVER(Partition By Year, Gender  Order By SUM(Births) DESC) AS rank_names
					FROM names
					GROUP BY 1,2,3
					ORDER BY 1,4 DESC)
SELECT 
	Year, 
    Name, 
    Gender, 
    rank_names
FROM ranking_name
WHERE rank_names IN (1,2,3) AND Gender ='F';

-- For each decade, return the 3 most popular girl names and 3 most popular boy names
SELECT * FROM(
WITH ranking_name_by_decade AS( SELECT 
						CASE 
							WHEN Year Between 1980 AND 1990 THEN '80s'
                            WHEN Year Between 1990 AND 1999 THEN '90s'
                            WHEN Year Between 2000 AND 2010 THEN '2000'
                            ELSE 'oh uh check logic again'
						END AS decade,
						Name, 
						Gender,
						SUM(Births) AS num_babies
					FROM names
					GROUP BY 1,2,3
					ORDER BY 1,4 DESC)
SELECT 
	decade, 
    Name, 
    Gender, 
    num_babies,
    ROW_NUMBER() OVER(Partition By decade, Gender  Order By num_babies DESC) AS rank_names
FROM ranking_name_by_decade) AS top_three

WHERE rank_names IN (1,2,3)
ORDER BY decade;

-- 3. Compare popularity across regions
-- Return the number of babies born in each of the six regions (NOTE: The state of MI should be in the Midwest region)
	-- State in names table
SELECT * FROM regions;
SELECT * FROM Names;
SELECT COUNT(DISTINCT state) FROM regions ;

-- Clean the New England region and add MI state to the region table
DROP TABLE IF EXISTS  clean_regions;
CREATE TEMPORARY TABLE clean_regions
SELECT 
	State, 
    CASE WHEN Region = 'New England' THEN 'New_England' ELSE Region END AS clean_region
FROM regions
UNION
SELECT 'MI' AS State, 'Midwest' AS Region;

SELECT COUNT(DISTINCT clean_region) FROM clean_regions; -- 6 region
SELECT DISTINCT State FROM clean_regions WHERE clean_region = 'Midwest';-- check MI in Midwest region or No

SELECT 
	DISTINCT names.state, 
    clean_regions.clean_region
FROM names 
	LEFT JOIN clean_regions
		ON clean_regions.state = names.state
; -- check MI by join both table

SELECT 
	clean_regions.clean_region,
	SUM(Names.Births) AS num_babies
FROM clean_regions 
	INNER JOIN names
		ON clean_regions.state = names.state
GROUP BY 1
ORDER BY 2 DESC;

-- Return the 3 most popular girl names and 3 most popular boy names within each region

WITH name_by_region AS (SELECT 
							clean_region, 
							Gender,
							Name, 
							SUM(Births) AS num_babies
						FROM names
							INNER JOIN clean_regions
								ON names.state = clean_regions.state
						GROUP BY 1,2,3
						ORDER BY 4 DESC),
	popularity_by_region_gender AS (SELECT 
									clean_region, 
									Gender,
									Name, 
									ROW_NUMBER() OVER(Partition By clean_region, Gender ORDER BY num_babies DESC) AS popularity_by_region
								FROM name_by_region )

SELECT * FROM popularity_by_region_gender
WHERE popularity_by_region IN (1,2,3)
;

-- 4. Dig into some unique names
-- Find the 10 most popular androgynous names (names given to both females and males)
SELECT 
	name, 
    COUNT(DISTINCT gender) As num_genders, 
    SUM(births) AS num_babies
FROM names
GROUP BY 1
HAVING num_genders > 1
ORDER BY 3 DESC
LIMIT 10;

-- Find the length of the shortest and longest names
SELECT 
	Name, 
    length(name) AS length_name
FROM names
GROUP BY 1
ORDER BY 2
; -- 15 characters for the longest and 2 for the shortes

-- Identify the most popular short names (those with the fewest characters) and long names (those with the most characters)
-- the most popular short names
SELECT 
	Name, 
    length(name) AS length_name, 
    SUM(births) AS num_babies
FROM names
GROUP BY 1
HAVING length_name = 2
ORDER BY 3 DESC -- Ty with 29205 babies
;

-- the most popular long names
SELECT 
	Name, 
    length(name) AS length_name, 
    SUM(births) AS num_babies
FROM names
GROUP BY 1
HAVING length_name = 15
ORDER BY 3 DESC
; -- Franciscojavier with 52

-- The founder of Maven Analytics is named Chris. Find the state with the highest percent of babies named "Chris"
-- STEP 1: Count the total Chris name in each State
-- STEP 2: Count the toltal names in each state
-- STEP 3: Take total Chris name divide by total names to find the highest percent by DESC order the percentage.

WITH count_chris AS (SELECT 
						State,
						SUM(births) AS num_chris
					FROM names
					WHERE Name = 'Chris'
					GROUP BY 1), -- count chris name in each state

		count_all AS(SELECT 
						State,
						SUM(births) AS num_babies
					FROM names
					GROUP BY 1 -- count all names in each state
)

SELECT 	
	count_all.state,
	(num_chris/num_babies) * 100 AS pct_chris_in_each_state
FROM count_all 
	INNER JOIN count_chris
		ON count_all.State = count_chris.State
ORDER BY pct_chris_in_each_state DESC
;






