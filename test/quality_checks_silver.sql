/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

/* CHECKING bronze.crm_cust_info */

-- check for nulls or duplicates in PK
-- expectation: no result
SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- check for unwanted spaces
-- expectation: no result
SELECT 
	cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- data standardization & consistency
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;


/* CHECKING bronze.crm_prd_info */

-- check for nulls or duplicates in PK
-- expectation: no result
SELECT 
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- check for unwanted spaces
-- expectation: no result
SELECT 
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- check for null or negative numbers
-- expectation: no result
SELECT 
	prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- data standardization & consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

-- check for invalid date orders
SELECT
	*
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

/* CHECKING bronze.crm_sales_details */

-- check for unwanted spaces
-- expectation: no result
SELECT 
	sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- check for invalid dates
SELECT
	NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 OR 
		sls_due_dt > 20500101 OR sls_due_dt < 19900101

-- check for invalid date orders
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- check data consistency between sales, quantity and price
-- rule: sales = quantity * price
-- values must not be null, zero or negative
SELECT	DISTINCT
	sls_sales AS sls_sales_old,
	sls_quantity,
	sls_price AS sls_price_old,

	CASE 
		WHEN (sls_sales IS NULL) OR (sls_sales <= 0) OR (sls_sales != sls_quantity * ABS(sls_price))
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_slaes_new,

	CASE
		WHEN (sls_price IS NULL) OR (sls_price <= 0)
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS sls_new_price

FROM bronze.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price)
OR (sls_sales IS NULL) OR (sls_quantity IS NULL) OR (sls_price IS NULL)
OR (sls_sales <= 0) OR (sls_quantity <= 0) OR (sls_price <= 0)
ORDER BY sls_sales, sls_quantity, sls_price;

/* CHECKING bronze.erp_cust_az12 */

-- remove 'NAS' from cid
SELECT 
	cid,
	CASE
		WHEN cid LIKE '%NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	bdate,
	gen
FROM bronze.erp_cust_az12;

-- identify out of range dates
SELECT DISTINCT
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

-- data standardization and consistency
SELECT DISTINCT 
	gen,
	CASE 
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12;

/* CHECKING bronze.erp_loc_a101 */

-- remove '-' from cid
SELECT
	cid,
	REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101;

-- data standardization and consistency
SELECT DISTINCT
	cntry AS old_cntry,
	CASE
		WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
		WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

/* CHECKING bronze.erp_px_cat_g1v2 */

-- check for unwanted spaces
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- data standardization and consistency
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;
