SELECT *
FROM ConsumerPriceIndices_E_All_Data

-- DATA CLEANING 
--CREATING THE STAGING TABLES
-- 
Select *
INTO CPI_STAGING 
FROM ConsumerPriceIndices_E_All_Data
WHERE 1=0

INSERT INTO  CPI_STAGING 
SELECT *
FROM  ConsumerPriceIndices_E_All_Data

SELECT * 
FROM CPI_STAGING 

Select *
INTO AreaCodes_staging 
FROM CPI_AreaCodes
WHERE 1=0

INSERT INTO AreaCodes_staging 
SELECT *
FROM  CPI_AreaCodes

Select *
INTO NOFLAG_staging
FROM CPI_All_Data_NOFLAG
WHERE 1=0

INSERT INTO NOFLAG_staging 
SELECT *
FROM CPI_All_Data_NOFLAG

Select *
INTO Elements_staging
FROM CPI_Elements
WHERE 1=0

INSERT INTO Elements_staging
SELECT *
FROM CPI_Elements

Select *
INTO Flags_staging
FROM CPI_Flags
WHERE 1=0

INSERT INTO  Flags_staging
SELECT *
FROM CPI_Flags


Select *
INTO Flags_staging
FROM CPI_Flags
WHERE 1=0

INSERT INTO  Flags_staging
SELECT *
FROM CPI_Flags 

Select *
INTO itemCodes_Staging
FROM CPI_itemCODES
WHERE 1=0

INSERT INTO itemCodes_Staging
SELECT *
FROM CPI_itemCODES


-- CLEANING area_codes 
SELECT *
FROM AreaCodes_staging 

UPDATE AreaCodes_staging 
SET M49_CODE = REPLACE(M49_CODE,'''', '')

UPDATE AreaCodes_staging
SET Area = 'Aland Islands'
WHERE Area like '%land Islands%'

UPDATE AreaCodes_staging
SET Area = TRIM(Area), M49_Code = TRIM(M49_Code)

-- Cleaning Item codes
select *
FROM itemCodes_Staging

UPDATE itemCodes_Staging
SET Item = TRIM(Replace(Item,';', ' '))


-- Transposing the data 
Select *
FROM FACTS_CPI_VALUES

	SELECT
		Area_code,Item_code,Element_code,Months_code,
		CAST(REPLACE(Year_Raw, 'Y', '') AS INT) AS [Year_Num],
		TRY_CAST(Value_Raw AS DECIMAL(18,6)) AS [CPI_Value]
		INTO FACTS_CPI_VALUES
		FROM
(
Select 
		Area_code,Item_code,Element_code,Months_code,Y2000,Y2001,Y2002,Y2003,Y2004,Y2005,Y2006,
		Y2007,Y2008,Y2009,Y2010,Y2011,Y2012,Y2013,Y2014,Y2015,Y2016,Y2017,Y2018,Y2019,Y2020,
		Y2021,Y2022,Y2023,Y2024,Y2025

FROM NOFLAG_staging
) AS source_table 
UNPIVOT 
( Value_raw FOR Year_raw IN (Y2000,Y2001,Y2002,Y2003,Y2004,Y2005,Y2006,
		Y2007,Y2008,Y2009,Y2010,Y2011,Y2012,Y2013,Y2014,Y2015,Y2016,Y2017,Y2018,Y2019,Y2020,
		Y2021,Y2022,Y2023,Y2024,Y2025)
		) AS UnpivotedTable 
WHERE Value_raw IS NOT NULL 


-- Time series preparation 
Select Area_code, Item_code, Element_code,
DATEFROMPARTS(Year_NUM,([Months_code] - 7000), 1) AS [Reference_Date],
Year_num,
([Months_code] - 7000) as Month_num,
CPI_Value
INTO CPI_Production
FROM FACTS_CPI_VALUES	

SELECT *
FROM CPI_Production 


--  Creating dictionaries 
-- AREA CODES 

SELECT Area_code as AreaID,
		M49_code AS M49_code,
		area	 AS area
INTO Dimension_Areas 
FROM AreaCodes_staging 

-- Item 
SELECT 
    [Item_Code] AS ItemID,
    TRIM(Item) AS ItemName
INTO Dimension_Items
FROM itemCodes_Staging

--  Element Dictionary
SELECT 
    [Element_Code] AS ElementID,
    TRIM(Element) AS ElementName
INTO Dimension_Elements
FROM Elements_staging



SELECT * FROM AreaCodes_staging 
SELECT * FROM CPI_Production
SELECT * FROM itemCodes_Staging

SELECT 
    B.Area,
    C.Item AS Category,
    A.Reference_Date,
    A.CPI_Value
FROM CPI_Production A
JOIN Dimension_Areas B 
ON A.[Area_Code] = B.AreaID
JOIN itemCodes_Staging C 
ON A.[Item_Code] = C.[Item_Code]
ORDER BY B.Area, A.Reference_Date



-- Making it a relational table 
ALTER TABLE Dimension_Areas 
ADD CONSTRAINT PK_Dimension_Areas PRIMARY KEY (AreaID)

ALTER TABLE CPI_Production
ADD CONSTRAINT FK_CPI_Area 
FOREIGN KEY ([Area_Code]) REFERENCES Dimension_Areas(AreaID)

ALTER TABLE Dimension_Items
ADD CONSTRAINT PK_Items PRIMARY KEY (ItemID)

ALTER TABLE Dimension_Elements 
ADD CONSTRAINT PK_Elements PRIMARY KEY (ElementID)


-- 1. Dropping the Staging tables (The "Scaffolding")
DROP TABLE AreaCodes_staging
DROP TABLE CPI_STAGING
DROP TABLE Elements_staging
DROP TABLE Flags_staging
DROP TABLE itemCodes_Staging
DROP TABLE NOFLAG_staging

-- 2. Dropping the intermediary Fact table 
-- (We moved the data from here into CPI_Production already)
DROP TABLE FACTS_CPI_VALUES



-- final lap 
SELECT TOP 100
    A.area AS Country,
    I.ItemName AS Category,
    E.ElementName AS Metric,
    P.Reference_Date,
    P.CPI_Value
FROM CPI_Production P
JOIN Dimension_Areas A ON P.Area_code = A.AreaID
JOIN Dimension_Items I ON P.Item_code = I.ItemID
JOIN Dimension_Elements E ON P.Element_code = E.ElementID
ORDER BY P.CPI_Value DESC


-- ANALYSIS PHASE

CREATE OR ALTER VIEW v_CPI_Dashboard_Data AS
SELECT 
    c.Area_code, 
    c.Item_code, 
    c.CPI_Value, 
    c.Year_num, 
    a.Area, 
    i.ItemName,
    
    -- This logic looks at the Item_Name text and assigns a Category
    CASE 
        WHEN i.ItemName LIKE '%Food%' THEN 'Food'
        WHEN i.ItemName LIKE '%General%' THEN 'General'
        ELSE 'Other'
    END AS Category,

    -- This logic looks for keywords to determine the Methodology
    CASE 
        WHEN i.ItemName LIKE '%weighted average%' THEN 'Weighted Average'
        WHEN i.ItemName LIKE '%median%' THEN 'Median'
        ELSE 'Standard' -- This catches the ones without a specific methodology
    END AS Methodology

-- Removing the noise/corrupted data

FROM cpi_production c
JOIN  Dimension_Areas a ON c.Area_code = a.AreaID
JOIN  Dimension_Items i ON c.Item_code = i.ItemID
WHERE c.CPI_Value < 1000; 














