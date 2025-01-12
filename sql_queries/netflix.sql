CREATE TABLE netflix_dup
LIKE netflix_titles;

INSERT netflix_dup
SELECT *
FROM netflix_titles;

SELECT * 
FROM netflix_dup;

SELECT * 
FROM netflix_titles;

SELECT*,
ROW_NUMBER() OVER(PARTITION BY show_id,type
                  ,title,director,cast) AS Duplicates
FROM netflix_dup;

WITH CTE_Dup AS   -- There is no duplicates
(
SELECT*,
ROW_NUMBER() OVER(PARTITION BY show_id,type
                  ,title,director,cast) AS Duplicates
FROM netflix_dup
)
SELECT*
FROM CTE_DUP
WHERE Duplicates >1; 

SET SQL_SAFE_UPDATES = 0;

SELECT COUNT(*) 
FROM netflix_dup
WHERE type = 'Movie';

SELECT COUNT(*) 
FROM netflix_dup
WHERE type = 'TV Show';

SELECT COUNT(*)
FROM netflix_dup
WHERE director IS NULL OR director = ''; 

-- List all movies released in a specific year (e.g., 2020)
SELECT title,release_year AS '2000s Movies'
FROM netflix_dup
WHERE release_year BETWEEN 2000 AND 2010
ORDER BY 2 ;

SELECT MAX(release_year),MIN(release_year) -- 2021,1975
FROM netflix_dup;

SELECT AVG(release_year) -- Avg 2015
FROM netflix_dup;

SELECT COUNT(*)
FROM netflix_dup
WHERE release_year BETWEEN 1975 AND 2000;

SELECT COUNT(*)
FROM netflix_dup
WHERE release_year BETWEEN 2000 AND 2021;

SELECT AVG(duration) AS 'Average_duration' -- 128.5 minute
FROM netflix_dup
WHERE type = 'Movie' AND release_year BETWEEN 1975 AND 2000;

SELECT AVG(duration) AS 'Average_duration' -- 96 minute 
FROM netflix_dup
WHERE type = 'Movie' AND release_year BETWEEN 2000 AND 2021;

SELECT title  
FROM netflix_dup
WHERE duration>(SELECT AVG(duration)
                FROM netflix_dup
                WHERE type = 'Movie');
                
-- Identify the longest and shortest movie 
SELECT title,duration -- 166 min
FROM netflix_dup
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) DESC
LIMIT 1;

SELECT title,duration -- 13 min
FROM netflix_dup
WHERE type = 'Movie'
ORDER BY CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) asc
LIMIT 1;

-- Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT title,director
FROM netflix_dup
WHERE director LIKE '%Daniel Sandu%';

 -- List all TV shows with more than 5 seasons
 SELECT
 * FROM netflix_dup
 WHERE type = 'Tv Show' and duration>5
 ORDER BY CAST(SUBSTRING_INDEX(duration,' ',1) AS UNSIGNED) DESC;

 -- Find how many movies actor 'Salman Khan' appeared in 1975-1980
SELECT COUNT(*)
FROM netflix_dup
WHERE cast LIKE '%Lorraine Gary%'
AND release_year BETWEEN 1975 AND 1980;

SELECT
*FROM netflix_dup
WHERE listed_in LIKE '%Documentaries%';

-- Find the top 5 countries with the most content on Netflix
SELECT country,
COUNT(show_id) AS Total_content
FROM netflix_dup
WHERE country IS NOT NULL
AND country NOT IN('')
GROUP BY country
ORDER BY 2 DESC
LIMIT 5;

SELECT AVG(duration),country
FROM netflix_dup
WHERE type = 'Movie'
GROUP BY country
ORDER BY 1 DESC;

--  Find all content without a director
SELECT*
FROM netflix_dup
WHERE director IS  NULL
OR director IN('');

-- Find content added in the last 5 years
UPDATE netflix_dup
SET date_added = STR_TO_DATE(date_added, '%M %d, %Y');

SELECT
* FROM netflix_dup
WHERE date_added >= DATE_SUB(CURRENT_DATE(), INTERVAL 10 YEAR)
ORDER BY date_added DESC;

-- Find the top 5 countries with the most content on Netflix with CTE's
WITH CTE_COUNT_TOTAL AS
(
SELECT country,
COUNT(*) AS total_content
FROM netflix_dup
WHERE country IS NOT NULL
GROUP BY country
),
RANK_COUNTRY AS
(
SELECT country,total_content,
RANK() OVER(ORDER BY total_content DESC) AS 'Rank'
FROM CTE_COUNT_TOTAL
)
SELECT country,total_content
FROM RANK_COUNTRY
WHERE COUNTRY IS NOT NULL
AND COUNTRY != ''
ORDER BY 'Rank'<=5;

-- Find the most common rating for movies and TV shows
WITH CTE_RATING_COUNT AS (
SELECT type,rating,
COUNT(*) AS rating_count
FROM netflix_dup
GROUP BY type,rating
),
RATING_RANK AS (
SELECT type,rating,rating_count,
RANK() OVER(ORDER BY rating_count) AS 'rate_counter'
FROM CTE_RATING_COUNT
)
SELECT type,rating,rating_count
FROM RATING_RANK
ORDER BY rate_counter desc;

-- Find each year and the numbers of content release in India on netflix. 
SELECT release_year,
COUNT(*) AS total_released_content
FROM netflix_dup
WHERE country LIKE '%India%'
GROUP BY release_year;

-- Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT 
	UNNEST(STRING_TO_ARRAY(casts, ',')) as actor,
	COUNT(*)
FROM netflix_dup
WHERE country = 'India'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Categorize the content based on the presence of the some of the keywords
SELECT category,type,
COUNT(*) AS category_counter
FROM (SELECT *,
	   CASE 
          WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad Content'
          ELSE 'Good Content'
        END AS category
        FROM netflix_dup) AS Categorized_Content
GROUP BY 1,2
ORDER BY 2 DESC;

 -- Count the number of content items in each genre       
SELECT 
	UNNEST(STRING_TO_ARRAY(listed_in, ',')) as genre,
	COUNT(*) as total_content
FROM netflix_dup
GROUP BY 1;
      
-- End



