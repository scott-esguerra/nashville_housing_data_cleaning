USE nashville_housing;

-- convert SaleDate (string) date datatype

SELECT SaleDate, STR_TO_DATE(SaleDate, "%M %d, %Y") AS This_is_what_we_want
FROM nashville_housing.housing;

UPDATE nashville_housing.housing
SET SaleDate = STR_TO_DATE(SaleDate, "%M %d, %Y");

-- Populate PropertyAddress

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;
    
-- check again if there are any nulls in PropertyAddress
SELECT PropertyAddress
FROM housing
WHERE PropertyAddress IS NULL;
    
-- Breaking out address into individual columns (Address, City, State)
    
SELECT * FROM housing;

SELECT 
	SUBSTRING_INDEX(PropertyAddress, ",", 1) AS Address,
    SUBSTRING_INDEX(PropertyAddress, ",", -1) AS City
FROM housing;

-- Create new columns (AddressSplit, CitySplit)
ALTER TABLE housing
ADD AddressSplit NVARCHAR(255);

UPDATE housing
SET AddressSplit = SUBSTRING_INDEX(PropertyAddress, ",", 1);

ALTER TABLE housing
ADD CitySplit NVARCHAR(255);

UPDATE housing
SET CitySplit = SUBSTRING_INDEX(PropertyAddress, ",", -1);

-- check PropertyAddress, AddressSplit and CitySplit Column
SELECT PropertyAddress, AddressSplit, CitySplit
FROM housing;

-- For the OwnerAddress
SELECT 
	SUBSTRING_INDEX(PropertyAddress, ",", 1) AS Address,
	SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", 2), ",", -1) AS City,
    SUBSTRING_INDEX(OwnerAddress, ",", -1) AS State
FROM housing;

-- Create new columns (OwnerAddressSplit, OwnerCitySplit, OwnerStateSplit)
ALTER TABLE housing
ADD OwnerAddressSplit NVARCHAR(255);

UPDATE housing
SET OwnerAddressSplit = SUBSTRING_INDEX(PropertyAddress, ",", 1);

ALTER TABLE housing
ADD OwnerCitySplit NVARCHAR(255);

UPDATE housing
SET OwnerCitySplit = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ",", 2), ",", -1);

ALTER TABLE housing
ADD OwnerStateSplit NVARCHAR(255);

UPDATE housing
SET OwnerStateSplit = SUBSTRING_INDEX(OwnerAddress, ",", -1);

SELECT * FROM housing;

-- Change Y and N to Yes and No in "SoldAsVacant"

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT
	COUNT(SoldAsVacant),
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END AS This_is_what_we_want
FROM housing
GROUP BY SoldAsVacant
ORDER BY 1;

UPDATE housing
SET SoldAsVacant = 
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END;

-- Remove duplicates
-- Note: It's never a good practice to remove duplicate in the actual table of a raw data company data. Just do it in temp table.

WITH CTE AS (
	SELECT *,
		ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY UniqueID) AS row_num
	FROM housing
	ORDER BY ParcelID
    )
SELECT *
FROM CTE
WHERE row_num > 1
ORDER BY parcelID;

-- Delete using this statement

-- Not efficient code
DELETE a
-- SELECT a.*
FROM housing a
INNER JOIN housing b
WHERE a.UniqueID < b.UniqueID
	AND a.ParcelID = b.ParcelID
    AND b.PropertyAddress = b.PropertyAddress
    AND a.SalePrice = b.SalePrice
    AND a.SaleDate = b.SaleDate
    AND a.LegalReference = b.LegalReference;


SELECT *
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID,
														PropertyAddress,
                                                        SalePrice,
                                                        SaleDate,
                                                        LegalReference
                                                        ORDER BY UniqueID) AS row_num
                                                        FROM housing) AS Temp_table
WHERE row_num > 1;

DELETE
FROM housing
WHERE UniqueID IN (SELECT UniqueID FROM (SELECT UniqueID, ROW_NUMBER() OVER (PARTITION BY ParcelID,
																			PropertyAddress,
																			SalePrice,
																			SaleDate,
																			LegalReference
																			ORDER BY UniqueID) AS row_num
																			FROM housing) AS Temp_table
																			WHERE row_num > 1);

-- Delete unused columns (PropertyAddress, OwnerAddress, TaxDistrict)
-- Again, warning like the DELETE function

SELECT * FROM housing;

ALTER TABLE housing
DROP COLUMN PropertyAddress, 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict;












    