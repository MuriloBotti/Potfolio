USE PortfolioProject	

-- Select data that we are going to use
SELECT 
	Location, 
	FORMAT(CONVERT(DATE, date), 'dd/MM/yyyy') AS Date, 
	FORMAT(total_cases, '#,0') AS TotalCases,
	FORMAT(new_cases, '#,0') AS NewCases,
	FORMAT(total_deaths, '#,0') AS TotalDeaths,
	FORMAT(population, '#,0') AS Population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, CONVERT(DATE, date)


-- TOTAL CASES VS. TOTAL DEATHS
-- Death Percentage all Locations
SELECT 
	location, 
	FORMAT(CONVERT(DATE, date), 'dd/MM/yyyy') AS Date, 
	FORMAT(total_cases, '#,0') AS TotalCases,
	ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM CovidDeaths
ORDER BY location, CONVERT(DATE, date)

-- Death Percentage Brazil
SELECT 
	location, 
	FORMAT(CONVERT(DATE, date), 'dd/MM/yyyy') AS Date, 
	FORMAT(total_cases, '#,0') AS TotalCases, 
	ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%Brazil%' AND continent IS NOT NULL
ORDER BY location,CONVERT(DATE, date)



-- Total Cases vs Population
-- Percentage of Population Infected with Covid
SELECT 
	location, 
	FORMAT(CONVERT(DATE, date), 'dd/MM/yyyy') AS Date, 
	FORMAT(population, '#,0') AS Population,
	FORMAT(total_cases, '#,0') AS TotalCases, 
	ROUND((total_cases/population)*100,2) AS PopulationInfectedPercentage
FROM CovidDeaths
WHERE location LIKE '%Brazil%' AND continent IS NOT NULL
ORDER BY location, CONVERT(DATE, date)

-- Countries with Highest Infection Rate compared to Population
SELECT 
	location, 
	FORMAT(population, '#,0') AS Population,
	FORMAT(MAX(total_cases), '#,0') AS HighestInfectionCount, 
	ROUND(MAX((total_cases/population))*100,2) AS PopulationInfectedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PopulationInfectedPercentage DESC

-- Counties with Highest Death Count per Population
SELECT 
	location, 
	FORMAT(MAX(CAST(total_deaths AS INT)),'#,0') AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location	
ORDER BY MAX(CAST(total_deaths AS INT)) DESC



-- BREAKING THINGS DOWN BY CONTINENT
-- Continents with Highest Deaths Count per Population
SELECT 
	location, 
	FORMAT(MAX(CAST(total_deaths AS INT)),'#,0') AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY MAX(CAST(total_deaths AS INT)) DESC



-- GLOBAL NUMBERS
-- Death Percentage per Day
SELECT 
	FORMAT(CONVERT(DATE, date), 'dd/MM/yyyy') AS Date,
	FORMAT(SUM(new_cases), '#,0') AS TotalCasesPerDay, 
	FORMAT(SUM(new_deaths), '#,0') AS TotalDeathPerDay,
	FORMAT((SUM(new_deaths) * 100.0) / NULLIF(SUM(new_cases), 0), 'N2') AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY CONVERT(DATE, date), SUM(new_cases)

-- Death Percentage Overall
SELECT
	FORMAT(SUM(new_cases), '#,0') AS TotalCases, 
	FORMAT(SUM(new_deaths), '#,0') AS TotalDeaths,
	FORMAT((SUM(new_deaths) * 100.0) / NULLIF(SUM(new_cases), 0), 'N2') AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Population vs. Vaccination (PopvsVac)
SELECT
	CovidDeaths.continent,
	CovidDeaths.location,
	FORMAT(population, '#,0') AS Population,
	FORMAT(CONVERT(DATE, CovidDeaths.date), 'dd/MM/yyyy') AS Date,
	ROUND((total_cases/CovidDeaths.population)*100,2) AS PopulationInfectedPercentage,
	FORMAT(CAST(CovidVaccinations.new_vaccinations AS INT), '#,0') AS NewVaccinations,
	SUM(CAST(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths
JOIN CovidVaccinations
	ON 
		CovidDeaths.location = CovidVaccinations.location 
		AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL
ORDER BY location, CONVERT(DATE, CovidDeaths.date)


-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, Date, Population, PopulationInfectedPercentage, NewVaccinations, RollingPeopleVaccinated) 
AS
(
    SELECT
        CovidDeaths.continent,
        CovidDeaths.location,
        CONVERT(DATE, CovidDeaths.date) AS Date,
        CovidDeaths.population AS Population,
        ROUND((total_cases/CovidDeaths.population)*100, 2) AS PopulationInfectedPercentage,
        FORMAT(CAST(CovidVaccinations.new_vaccinations AS INT), '#,0') AS NewVaccinations,
        SUM(CAST(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.date) AS RollingPeopleVaccinated
    FROM CovidDeaths
    JOIN CovidVaccinations
        ON CovidDeaths.location = CovidVaccinations.location 
        AND CovidDeaths.date = CovidVaccinations.date
    WHERE CovidDeaths.continent IS NOT NULL
)
SELECT 
    continent,
    location,
    FORMAT(Date, 'dd/MM/yyyy') AS Date,
    FORMAT(Population, '#,0') AS Population,
    PopulationInfectedPercentage,
    NewVaccinations,
    FORMAT(RollingPeopleVaccinated, '#,0') AS RollingPeopleVaccinated,
    FORMAT((RollingPeopleVaccinated / CONVERT(DECIMAL(18, 2), Population)) * 100, '0.00') AS VaccinationPercentage
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    NewVaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
    SELECT
        CovidDeaths.continent,
        CovidDeaths.location,
        CovidDeaths.date,
        CovidDeaths.population,
        CovidVaccinations.new_vaccinations,
        SUM(CAST(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.date) AS RollingPeopleVaccinated
    FROM CovidDeaths
    JOIN CovidVaccinations
        ON CovidDeaths.location = CovidVaccinations.location 
        AND CovidDeaths.date = CovidVaccinations.date
    WHERE CovidDeaths.continent IS NOT NULL;

SELECT
	Continent,
	Location,
	FORMAT(CONVERT(DATE, date), 'dd/MM/yyyy') AS Date,
	FORMAT(Population, '#,0') AS Population,
	FORMAT(NewVaccinations, '#,0') AS NewVaccinations,
	FORMAT(RollingPeopleVaccinated, '#,0') AS RollingPeopleVaccinated,
	(RollingPeopleVaccinated/Population)*100 AS PercentagePeopleVaccinated
FROM #PercentPopulationVaccinated
WHERE continent IS NOT NULL



-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	CovidDeaths.continent,
	CovidDeaths.location,
	FORMAT(population, '#,0') AS Population,
	FORMAT(CONVERT(DATE, CovidDeaths.date), 'dd/MM/yyyy') AS Date,
	ROUND((total_cases/CovidDeaths.population)*100,2) AS PopulationInfectedPercentage,
	FORMAT(CAST(CovidVaccinations.new_vaccinations AS INT), '#,0') AS NewVaccinations,
	SUM(CAST(CovidVaccinations.new_vaccinations AS BIGINT)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths
JOIN CovidVaccinations
	ON 
		CovidDeaths.location = CovidVaccinations.location 
		AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL




SELECT *
FROM PercentPopulationVaccinated