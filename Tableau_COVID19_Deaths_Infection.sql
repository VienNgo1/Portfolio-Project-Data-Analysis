/*

QUERIES USED FOR TABLEAU PROJECT

*/

-- 1.
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- 2.
SELECT location, SUM(new_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE 
	continent IS NULL
	AND location NOT IN ('World', 'European Union', 'International', 'Low income', 'High income', 'Upper middle income', 'Lower middle income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3.
SELECT location, population, MAX(CAST(total_cases AS bigint)) AS HighestInfectionCount, MAX(CAST(total_cases AS bigint) / population) * 100 AS PercentPopulationInfected 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- 4.
SELECT location, population, date, MAX(CAST(total_cases AS bigint)) AS HighestInfectionCount, MAX(CAST(total_cases AS bigint) / population) * 100 AS PercentPopulationInfected 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC;
