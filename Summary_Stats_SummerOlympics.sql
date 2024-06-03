/*

-- THIS PROJECT ABOUT SUMMARY STATS ON SUMMER OLYMPICS
-- DATASET: summer
-- SKILL: WINDOW FUNCTION, FETCHING, RANKING, PAGING, AGGREATE WINDOW FUNCTION, TABLE

*/

SELECT *
FROM PortfolioProject..summer


-- USING ORDER BY IN OVER

-- Number each row in the dataset and order by years
SELECT *,
  -- Assign numbers to each row
  ROW_NUMBER() OVER (ORDER BY Year) AS Row_N
FROM PortfolioProject..summer
ORDER BY Row_N ASC;

-- Assign a number to each year in which Summer Olympic games were held so that rows with the most recent years have lower row numbers.
SELECT
  Year,
  -- Assign the lowest numbers to the most recent years
  ROW_NUMBER() OVER (ORDER BY year DESC) AS Row_N
FROM (
  SELECT DISTINCT Year
  FROM PortfolioProject..summer
) AS Years
ORDER BY Year;

-- For each athlete, count the number of medals he or she has earned.
SELECT
  -- Count the number of medals each athlete has earned
  Athlete,
  COUNT(*) AS Medals
FROM PortfolioProject..summer
GROUP BY Athlete
ORDER BY Medals DESC;

--Having wrapped the previous query in the Athlete_Medals CTE, rank each athlete by the number of medals they've earned.
WITH Athlete_Medals AS (
  SELECT
    -- Count the number of medals each athlete has earned
    Athlete,
    COUNT(*) AS Medals
  FROM PortfolioProject..summer
  GROUP BY Athlete)

SELECT
  -- Number each athlete by how many medals they've earned
  Athlete,
  ROW_NUMBER() OVER (ORDER BY medals DESC) AS Row_N
FROM Athlete_Medals
ORDER BY Medals DESC;

-- Return each year's gold medalists in the Men's 69KG weightlifting competition.
SELECT
  -- Return each year's champions' countries
  Year,
  Country AS champion
FROM PortfolioProject..summer
WHERE
  Discipline = 'Weightlifting' AND
  Event = '69KG' AND
  Gender = 'Men' AND
  Medal = 'Gold';

-- Having wrapped the previous query in the Weightlifting_Gold CTE, get the previous year's champion for each year.
WITH Weightlifting_Gold AS (
SELECT
  Year,
  Country AS champion
FROM PortfolioProject..summer
WHERE
  Discipline = 'Weightlifting' AND
  Event = '69KG' AND
  Gender = 'Men' AND
  Medal = 'Gold'
)
SELECT Year, Champion,
	LAG(Champion) OVER (ORDER BY Year ASC) AS LastChampion
FROM Weightlifting_Gold
ORDER BY Year ASC;

--Return the previous champions in Javelin Throw of each year's event by gender.
WITH Tennis_Gold AS (
SELECT DISTINCT	Gender, Year, Country
FROM PortfolioProject..summer
WHERE 
	Year >= 2000 AND
	Event = 'Javelin Throw' AND
	Medal = 'Gold'
)
SELECT Gender, Year, Country AS Champion, LAG(Country) OVER (PARTITION BY Gender ORDER BY Gender ASC) AS Last_champion
FROM Tennis_Gold
ORDER BY Gender ASC, Year ASC;

-- Return the previous champions in Athletics of each year's events by gender and event.
WITH Athletics_Gold AS(
SELECT Gender, Year, Event, Country
FROM PortfolioProject..summer
WHERE 
	Year >= 2000 AND
	Discipline = 'Athletics' AND
	Event IN ('100M', '10000M') AND
	Medal = 'Gold'
)
SELECT Gender, Year, Event, Country AS Champion, 
	LAG(Country) OVER (PARTITION BY Gender, Event ORDER BY Year ASC) AS LastChampion
FROM Athletics_Gold
ORDER BY Event ASC, Gender ASC, Year ASC;


-- USING FETCHING, RANKING AND PAGING


--For each year, fetch the current gold medalist and the gold medalist 3 competitions ahead of the current row.
WITH Discus_Medalists AS(
SELECT DISTINCT Year, Athlete
FROM PortfolioProject..summer
WHERE
	Medal = 'Gold' AND
	Event = 'Discus Throw' AND
	Gender = 'Women' AND
	Year >= 2000
)
SELECT Year, Athlete,
	LEAD(Athlete, 3) OVER(ORDER BY Year ASC)
FROM Discus_Medalists
ORDER BY Year ASC;

--Return all athletes and the first athlete ordered by alphabetical order.
WITH All_Male_Medalists AS (
  SELECT DISTINCT Athlete
  FROM PortfolioProject..summer
  WHERE Medal = 'Gold'
    AND Gender = 'Men')

SELECT
  Athlete,
  FIRST_VALUE(Athlete) OVER (
    ORDER BY Athlete ASC
  ) AS First_Athlete
FROM All_Male_Medalists;

-- Fetch the last city in which the Olympic games were held.
WITH Hosts AS (
  SELECT DISTINCT Year, City
    FROM PortfolioProject..summer)

SELECT
  Year,
  City,
  -- Get the last city in which the Olympic games were held
  LAST_VALUE(City) OVER (
   ORDER BY Year ASC
   RANGE BETWEEN
     UNBOUNDED PRECEDING AND
     UNBOUNDED FOLLOWING
  ) AS Last_City
FROM Hosts
ORDER BY Year ASC;

-- Rank each country's athletes by the count of medals they've earned 
-- the higher the count, the higher the rank 
-- without skipping numbers in case of identical values.
WITH Athlete_Medals AS(
	SELECT Country, Athlete, COUNT(*) AS Medals
	FROM PortfolioProject..summer
	WHERE Country IN ('JPN', 'KOR') AND Year >= 2000
	GROUP BY Country, Athlete
	HAVING COUNT(*) > 1)

SELECT Country, Athlete, DENSE_RANK() OVER (PARTITION BY Country ORDER BY Medals DESC) AS Rank_N
FROM Athlete_Medals
ORDER BY Country ASC, Rank_N ASC;

-- Split the distinct events into exactly 111 groups, ordered by event in alphabetical order.
WITH Events AS (
  SELECT DISTINCT Event
  FROM PortfolioProject..summer)

SELECT
  Event,
  NTILE(111) OVER (ORDER BY Event ASC) AS Page
FROM Events
ORDER BY Event ASC;

-- Split the athletes into top, middle, and bottom thirds based on their count of medals.
-- Return the average of each third.
WITH Athlete_Medals AS(
	SELECT Athlete, COUNT(*) AS Medals
	FROM PortfolioProject..summer
	GROUP BY Athlete
	HAVING COUNT(*) > 1),

	Thirds AS (
	SELECT Athlete, Medals, NTILE(3) OVER (ORDER BY Medals DESC) AS Third
	FROM Athlete_Medals)

SELECT Third, AVG(Medals) AS Avg_Medals
FROM Thirds
GROUP BY Third
ORDER BY Third ASC;

-- USING AGGREGATE WINDOW FUNCTIONS: FRAME, SUM(), MIN(), MAX(), MOVING AVERAGE AND TOTAL

-- Return the year, country, medals, the maximum medals earned and sum medals earned so far for each country, ordered by year in ascending order.
WITH Country_Medals AS (
	SELECT Year, Country, Count(*) AS Medals
	FROM PortfolioProject..summer
	WHERE 
		Country IN ('CHN', 'KOR', 'JPN') AND
		Medal = 'Gold' AND Year >= 2000
	GROUP BY Year, Country
)
SELECT Year, Country, Medals,
	MAX(Medals) OVER (PARTITION BY Country ORDER BY Year) AS Max_Medals,
	SUM(Medals) OVER (PARTITION BY Country ORDER BY Year) AS Sum_Medals
FROM Country_Medals
ORDER BY Country ASC, Year ASC;

--Return the year, medals earned, and the maximum medals earned
-- comparing only the current year and the next year.
-- comparing the last two and current rows' medals
WITH Scandinavian_Medals AS (
	SELECT Year, COUNT(*) AS Medals
	FROM PortfolioProject..summer
	WHERE
		Country IN ('DEN', 'NOR', 'FIN', 'SWE', 'ISL')
		AND Medal = 'Gold'
	GROUP BY Year)

SELECT 
	Year, Medals,
	-- Get the max of the current and next years'  medals
	MAX(Medals) OVER (ORDER BY Year ASC ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS Max_Medals_1,
	-- Get the max of the last two and current rows' medals
	MAX(Medals) OVER (ORDER BY Year ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Max_Medals_2
FROM Scandinavian_Medals
ORDER BY Year ASC;

-- Calculate the 3-year moving average of medals earned.
-- Calculate each country's 3-game moving total
WITH Russian_Medals AS (
	SELECT Year, Country, COUNT(*) AS Medals
	FROM PortfolioProject..summer
	WHERE Country = 'RUS' AND Medal = 'Gold' AND Year >= 1980
	GROUP BY Year, Country)

SELECT Year, Country, Medals,
	--- Calculate the 3-year moving average of medals earned
	AVG(Medals) OVER (ORDER BY Year ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Medals_MA,
	-- Calculate each country's 3-game moving total
	SUM(Medals) OVER (PARTITION BY Country ORDER BY Year ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Medals_MS
FROM Russian_Medals
ORDER BY Year ASC;
	

-- USING TABLE

--Create the correct extension.
--Fill in the column names of the pivoted table.

SELECT 
    Gender,
    MAX(CASE WHEN Year = 2008 THEN Country ELSE NULL END) AS "2008",
    MAX(CASE WHEN Year = 2012 THEN Country ELSE NULL END) AS "2012"
FROM(
	SELECT Gender, Year, Country
	FROM PortfolioProject..summer
	WHERE 
		Year IN (2008, 2012)
		AND Medal = 'Gold'
		AND Event = 'Pole Vault'
) AS SourceTable
GROUP BY 
    Gender
ORDER BY 
    Gender ASC;



-- Count the gold medals that France (FRA), the UK (GBR), and Germany (GER) have earned per country and year.
-- Select the country and year columns, then rank the three countries by how many gold medals they earned per year.
-- Pivot the query's results by Year by filling in the new table's correct column names.
SELECT 
	Country,
	MAX(CASE WHEN Year = 2004 THEN rank ELSE NULL END) AS "2004",
	MAX(CASE WHEN Year = 2008 THEN rank ELSE NULL END) AS "2008",
	MAX(CASE WHEN Year = 2012 THEN rank ELSE NULL END) AS "2012"
FROM(
	SELECT Country, Year,
		RANK() OVER (PARTITION BY Year ORDER BY Awards DESC) AS rank
	FROM(
		SELECT Country, Year, COUNT(*) AS Awards
		FROM PortfolioProject..summer
		WHERE
			Country IN ('FRA', 'GBR', 'GER')
			AND Year IN (2004, 2008, 2012)
			AND Medal = 'Gold'
	GROUP BY Country, Year
) AS Country_Awards
    ) AS ranked_data

GROUP BY Country
ORDER BY Country ASC;

-- Count the gold medals awarded per country and gender.
-- Generate Country-level gold award counts.
-- Generate all possible group-level counts (per gender and medal type subtotals and the grand total).

SELECT
  COALESCE(Country, 'All countries') AS Country,
  COALESCE(Gender, 'All genders') AS Gender,
  COUNT(*) AS Gold_Awards
FROM PortfolioProject..summer
WHERE
  Year = 2004
  AND Medal = 'Gold'
  AND Country IN ('DEN', 'NOR', 'SWE')
-- Generate Country-level subtotals
GROUP BY ROLLUP(Country, Gender)
ORDER BY Country ASC, Gender ASC;

SELECT
  COALESCE(Country, 'All countries') AS Country,
  COALESCE(Gender, 'All genders') AS Gender,
  COUNT(*) AS Gold_Awards
FROM PortfolioProject..summer
WHERE
  Year = 2004
  AND Medal = 'Gold'
  AND Country IN ('DEN', 'NOR', 'SWE')
-- Generate Country-level subtotals
GROUP BY CUBE(Country, Gender)
ORDER BY Country ASC, Gender ASC;

-- Rank countries by the medals they've been awarded.
-- Return the top 3 countries by medals awarded as one comma-separated string.

WITH Country_Medals AS (
  SELECT
    Country,
    COUNT(*) AS Medals
  FROM PortfolioProject..summer
  WHERE Year = 2000
    AND Medal = 'Gold'
  GROUP BY Country),

  Country_Ranks AS (
  SELECT
    Country,
    RANK() OVER (ORDER BY Medals DESC) AS Rank
  FROM Country_Medals)

-- Compress the countries column
SELECT STRING_AGG(Country, ', ') AS Rank_name
FROM Country_Ranks
-- Select only the top three ranks
WHERE Rank <= 3;
