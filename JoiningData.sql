/*

-- THIS PROJECT ABOUT JOINING DATA IN COUNTRY DATASET
-- SKILL: INNER JOIN, OUTER JOIN, LEFT JOIN, RIGHT JOIN, CROSS JOIN, SEFT JOIN, SUBQUERIES IN SELECT, WHERE AND FROM

*/




-- USING INNER JOIN AND MULTIPLE JOIN

-- Select fields with aliases
SELECT c.code AS country_code, country_name, year, inflation_rate
FROM PortfolioProject..countries AS c
-- Join to economies (alias e)
INNER JOIN PortfolioProject..economies AS e
-- Match on code field using table aliases
ON c.code = e.code

-- Select country and language names, aliased
SELECT c.country_name AS country, l.name AS language
-- From countries (aliased)
FROM countries AS c 
-- Join to languages (aliased)
INNER JOIN languages AS l   
-- Use code as the joining field with the USING keyword
ON c.code = l.code;

SELECT country_name, e.year, fertility_rate, unemployment_rate
FROM countries AS c
INNER JOIN populations AS p
ON c.code = p.country_code
INNER JOIN economies AS e
ON c.code = e.code
-- Add an additional joining condition such that you are also joining on year
	AND e.year = p.year;

-- USING OUTER JOIN, LEFT JOIN, RIGHT JOIN, CROSS JOIN AND SELF JOIN

-- Complete the LEFT JOIN with the countries table on the left and the economies table on the right on the code field.
SELECT country_name, region, gdp_percapita
FROM countries AS c
LEFT JOIN economies AS e
-- Match on code fields
ON c.code = e.code
-- Filter for the year 2010
WHERE year = 2010;

-- Write a new query using RIGHT JOIN that produces an identical result to the LEFT JOIN provided.
SELECT countries.country_name AS country, languages.name AS language, [percent]
FROM languages
RIGHT JOIN countries
ON languages.code = countries.code
ORDER BY language;

-- Perform a full join with countries (left) and currencies (right). Filter for the North America region or NULL country names.
SELECT country_name AS country, region, basic_unit
FROM countries
-- Join to currencies
FULL JOIN currencies
ON countries.code = currencies.code
-- Where region is North America or null
WHERE region = 'North America'
	OR country_name IS NULL
ORDER BY region;

--Chain this join with another FULL JOIN, placing currencies on the right, joining on code again.
SELECT 
	c1.country_name AS country, 
    region, 
    l.name AS language,
	basic_unit, 
    frac_unit
FROM countries as c1 
-- Full join with languages (alias as l)
FULL JOIN languages AS l 
ON c1.code = l.code
-- Full join with currencies (alias as c2)
FULL JOIN currencies AS c2
ON l.code = c2.code
WHERE region LIKE 'M%esia';

-- CROSS JOIN: Complete the code to perform an INNER JOIN of countries AS c with languages AS l using the code field to obtain the languages currently spoken in the two countries.
SELECT c.country_name AS country, l.name AS language
-- Inner join countries as c with languages as l on code
FROM countries AS c
INNER JOIN languages AS l
ON c.code = l.code
WHERE c.code IN ('PAK','IND')
	AND l.code in ('PAK','IND');

-- SELF JOIN: Perform an inner join of populations with itself ON country_code, aliased p1 and p2 respectively.
-- Select the country_code from p1 and the size field from both p1 and p2, aliasing p1.size as size2010 and p2.size as size2015 (in that order).
SELECT p1.country_code, p1.size AS size2010, p2.size AS size2015
-- Join populations as p1 to itself, alias as p2, on country code
FROM populations AS p1
INNER JOIN populations AS p2
ON p1.country_code = p2.country_code;
-- Since you want to compare records from 2010 and 2015, eliminate unwanted records by extending the WHERE statement to include only records where the p1.year matches p2.year - 5.
SELECT 
	p1.country_code, 
    p1.size AS size2010, 
    p2.size AS size2015
FROM populations AS p1
INNER JOIN populations AS p2
ON p1.country_code = p2.country_code
WHERE p1.year = 2010
-- Filter such that p1.year is always five years before p2.year
    AND p1.year = p2.year - 5;


-- USING UNION, UNION ALL, INTERSECT, EXCEPT

-- UNION: Perform a set operation to combine the two queries you just created, ensuring you do not return duplicates.
-- Select all fields from economies2015
SELECT *
FROM economies2015 
-- Set operation
UNION
-- Select all fields from economies2019
SELECT *
FROM economies2019
ORDER BY code, year;
-- Query that determines all pairs of code and year from economies and populations, without duplicates
SELECT code, year
FROM economies
UNION 
SELECT country_code, year
FROM populations
ORDER BY code, year;

-- INTERSECT: Return all city names that are also country names.
SELECT name
FROM cities
INTERSECT
SELECT country_name
FROM countries;

-- EXCEPT: Return all cities that do not have the same name as a country.
SELECT name 
FROM cities
EXCEPT
SELECT country_name
FROM countries
ORDER BY name;

-- USING SEMI JOIN, SUBQUERY

-- SEMI JOIN: Create a semi join out of the two queries you've written, which filters unique languages returned in the first query for only those languages spoken in the 'Middle East'.
SELECT DISTINCT name
FROM languages
-- Add syntax to use bracketed subquery below as a filter
WHERE code IN
    (SELECT code
    FROM countries
    WHERE region = 'Middle East')
ORDER BY name;

SELECT code, country_name
FROM countries
WHERE continent = 'Oceania'
-- Filter for countries not included in the bracketed subquery
  AND code NOT IN
    (SELECT code
    FROM currencies);

-- Subqueries inside where: use this calculation to filter populations for all records where life_expectancy is 1.15 times higher than average.
SELECT *
FROM populations
-- Filter for only those populations where life expectancy is 1.15 times higher than average
WHERE life_expectancy > 1.15 *
  (SELECT AVG(life_expectancy)
   FROM populations
   WHERE year = 2015) 
    AND year = 2015;

-- Return the name, country_code and urbanarea_pop for all capital cities (not aliased).
-- Select relevant fields from cities table
SELECT name, country_code, urbanarea_pop
FROM cities
-- Filter using a subquery on the countries table
WHERE name IN
    (SELECT capital
    FROM countries)
ORDER BY urbanarea_pop DESC;

-- Subqueries inside select: -- Find top nine countries with the most cities
SELECT TOP 9 countries.country_name AS country, COUNT(*) AS cities_num
FROM countries
LEFT JOIN cities
ON countries.code = cities.country_code
GROUP BY country_name
-- Order by count of cities as cities_num
ORDER BY cities_num DESC, country;

-- Subqueries inside from: 

-- Select relevant fields
SELECT code, inflation_rate, unemployment_rate
FROM economies
WHERE year = 2015 
  AND code NOT IN
-- Subquery returning country codes filtered on gov_form
    (SELECT code
     FROM countries
     WHERE (gov_form LIKE '%Monarchy%' OR gov_form LIKE '%Republic%'))
ORDER BY inflation_rate;

-- Select fields from cities
SELECT TOP 10
	name, 
    country_code, 
    city_proper_pop, 
    metroarea_pop,
    city_proper_pop / metroarea_pop * 100 AS city_perc
FROM cities
-- Use subquery to filter city name
WHERE name IN
  (SELECT capital
   FROM countries
   WHERE (continent = 'Europe'
   OR continent LIKE '%America'))
-- Add filter condition such that metroarea_pop does not have null values
	  AND metroarea_pop IS NOT NULL
-- Sort and limit the result
ORDER BY city_perc DESC;


