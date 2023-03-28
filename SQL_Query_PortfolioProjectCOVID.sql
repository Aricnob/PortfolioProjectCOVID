SELECT *
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM PortfolioProjectCOVID.dbo.CovidVaccinations
ORDER BY 3,4

-- Select Data that we are to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjectCOVID..CovidDeaths
ORDER BY 1,2

-- Looking at total_cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL) / (total_cases))*100 AS Death_Percentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at total_cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS Pop_Percentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at countries with hightest infection rate compared to population
SELECT location, MAX(total_cases) AS Higest_Infection_Count, population, MAX((total_cases)/population)*100 AS Percent_Population_Infected
FROM PortfolioProjectCOVID..CovidDeaths
GROUP BY location, population
ORDER BY Percent_Population_Infected desc

-- Looking at countries with hightest mortality rate per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY Total_Death_Count desc

-- Looking at countries total death count vs percentage population mortality
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count, (MAX(CAST(total_deaths AS DECIMAL)) / MAX(population))*100
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY Total_Death_Count desc

-- Looking at total death per continent - not accurate for some reason
SELECT continent, MAX(Cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers by date
SELECT date, SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 AS Death_Percentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1

-- Global total cases, total deaths, and death percentage
SELECT SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 AS Death_Percentage
FROM PortfolioProjectCOVID..CovidDeaths
--WHERE continent is not null
ORDER BY 1

-- Looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated, --(RollingPeopleVaccinated/population)*100
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USE CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopVsVac
ORDER BY 2,3

-- TEMP Table
DROP TABLE IF exists #PercentPopulationVaccinated
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
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated
ORDER BY 2,3


-- Creating view to store data for later
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3