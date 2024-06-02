/*
-- DATASET COVID-19 LAST UPDATED ON 30/05/2024
-- THIS PROJECT ABOUT EXPLORATION DATA ANALYSIS SKILL OF COVID19
-- SKILL USED: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select all columns in CovidDeaths Database
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 4 DESC;

-- Select all columns in CovidVaccinations Database
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4;

--Select Data is going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Looking at Total Cases vs. Total_Deaths
-- The Percentage of Deaths out of the total number of cases in Vietnam from 2020 to 2024
-- To show likelihood of dying if infected in Vietnam
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%nam' 
AND continent IS NOT NULL
ORDER BY 2 DESC;

-- Looking at a Countries which is the highest infection rate compared to population
-- To show the Percent Population Infect in each Country and find the country has the highest infection
SELECT location, population, MAX(CAST(total_cases AS float)) AS HighestInfectionCount, Max((CAST(total_cases AS float)/population) *100) AS PercentPopulationInfect
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfect DESC;

-- To show Countries with Highest Death Count per Population
-- In this Query, we saw that a location including World, High income, it not be a country so we should remove those row by remove variable NULL in continent column
SELECT location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Showing the continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing total of new cases and new deaths to calculate percent of death
SELECT SUM(new_cases) AS Total_cases, SUM(new_deaths) AS Total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS PercentDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND (new_cases <> 0 OR new_deaths <> 0)
ORDER BY 1, 2;


-- Looking at Total Population vs Vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3;

-- Use Common table expression to perform Calculation on Partition By in previous query

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM PopVsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;



-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(CAST(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

-- Looking at people in Vietnam were vaccinated
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated
WHERE location LIKE '%nam';
