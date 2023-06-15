USE PortfolioProject

SELECT *
FROM ElectricityBySource

SELECT *
FROM ElectricityAccess

SELECT *
FROM PopulationByYear

-- Select data that we are going to use
SELECT
	Entity,
	Code,
	Year,
	FORMAT([Coal (% electricity)], 'N2') AS [Coal%],
	FORMAT([Gas (% electricity)], 'N2') AS [Gas%],
	FORMAT([Hydro (% electricity)], 'N2') AS [Hydro%],
	FORMAT([Solar (% electricity)], 'N2') AS [Solar%],
	FORMAT([Wind (% electricity)], 'N2') AS [Wind%],
	FORMAT([Oil (% electricity)], 'N2') AS [Oil%],
	FORMAT([Nuclear (% electricity)], 'N2') AS [Nuclear%],
	FORMAT([Bioenergy (% electricity)], 'N2') AS [Bioenergy%]
FROM ElectricityBySource


-- OVERALL STATUS
-- Avarege Access to Eletricity over the years
SELECT AVG([Access to electricity (% of population)]) AS AvgAccessToElectricity
FROM ElectricityAccess


-- BREAKING THINGS DOWN BY SOURE TYPE
-- Top 10 Countries with Highest Renewable Energy
SELECT TOP 10
	Entity,
	Year,
	[Hydro (% electricity)] AS [Hydro%],
	[Solar (% electricity)] AS [Solar%],
	[Wind (% electricity)] AS [Wind%],
	[Bioenergy (% electricity)] AS [Bioenergy%],
	[Hydro (% electricity)] + [Solar (% electricity)] + [Wind (% electricity)] + [Bioenergy (% electricity)] AS [RenewableEnergy%]
FROM ElectricityBySource
WHERE Year = '2022'
ORDER BY [RenewableEnergy%] DESC

-- Growth of Solar Source
SELECT
    Entity,
    Year,
    FORMAT([Solar (% electricity)], 'N2') AS [Solar%],
    CASE
        WHEN Lag([Solar (% electricity)]) OVER (PARTITION BY Entity ORDER BY Year) <> 0 THEN
            FORMAT(([Solar (% electricity)] - Lag([Solar (% electricity)]) OVER (PARTITION BY Entity ORDER BY Year)) / Lag([Solar (% electricity)]) OVER (PARTITION BY Entity ORDER BY Year) * 100, 'N2')
        ELSE
            'N/A'
    END AS [Growth%]
FROM ElectricityBySource
WHERE Code IS NOT NULL --AND Entity = 'Brazil'
ORDER BY Entity, Year

-- Countries dependent of Nuclear Power
SELECT
	Entity,
	Year,
	FORMAT([Nuclear (% electricity)], 'N2') AS [Nuclear%]
FROM ElectricityBySource
WHERE Year = '2022' 
	AND Code IS NOT NULL 
	AND [Nuclear (% electricity)] IS NOT NULL 
	AND CAST([Nuclear (% electricity)] AS INT) <> 0
ORDER BY CAST([Nuclear (% electricity)] AS INT) DESC

-- Counties where Renewable Energy sources was less than 10%.
SELECT
	Entity,
	Year,
	FORMAT([Coal (% electricity)], 'N2') AS [Coal%],
	FORMAT([Gas (% electricity)], 'N2') AS [Gas%],
	FORMAT([Oil (% electricity)], 'N2') AS [Oil%],
	FORMAT([Nuclear (% electricity)], 'N2') AS [Nuclear%],
	FORMAT([Coal (% electricity)] + [Gas (% electricity)] + [Oil (% electricity)] + [Nuclear (% electricity)], 'N2') AS [NonRenewableEnergy%],
	FORMAT([Hydro (% electricity)] + [Solar (% electricity)] + [Wind (% electricity)] + [Bioenergy (% electricity)], 'N2') AS [RenewableEnergy%]
FROM ElectricityBySource
WHERE 
	Year = '2022'
	AND Code IS NOT NULL 
	AND [Hydro (% electricity)] + [Solar (% electricity)] + [Wind (% electricity)] + [Bioenergy (% electricity)] < 10
ORDER BY [RenewableEnergy%] DESC


-- BREAKING DOWN BY POPULATION
-- Growth Population with Access over the Years
SELECT 
	ea.Entity, 
	ea.Year, 
	FORMAT(ea.[Access to electricity (% of population)], 'N2') AS [EleticityAccess%],
	FORMAT(py.Population, '#,0') AS Population,
	FORMAT(CAST(ea.[Access to electricity (% of population)] * py.Population AS BIGINT) / 100, 'N0') AS PopulationWithAccess
FROM ElectricityAccess ea
JOIN PopulationByYear py 
	ON ea.Entity = py.[Country name] 
	AND ea.Year = py.Year
WHERE ea.Code IS NOT NULL
ORDER BY 1,2
