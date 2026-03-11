CREATE OR REPLACE VIEW UMDB_BMCOANDS_PRD.ADMIN.TABLEAU_DBA_ON_PREM_LICENSE_COMPLIANCE_VIEW(
	ADJUSTED_CSN,
	ADJUSTED_CSN_NAME,
	INSTALL_COMPANY_NAME,
	INSTALL_COMPANY_COUNTRY,
	INSTALL_SALES_REGION,
	PAM_DBA,
	RENEWAL_REP,
	BRV_TCV_USDB,
	BRV_ACV_USDB,
	ERV_TCV_USDB,
	ERV_ACV_USDB,
	INDUSTRY_BY_CSN,
	LTV_ACV_USDB,
	LTV_TCV_USDB,
	LAST_BOOKING_DATE,
	TERM_START_DATE,
	TERM_END_DATE,
	PRODUCT_BUSINESS_UNIT,
	PRODUCT_FAMILY,
	PRODUCT_NAME,
	RPC_UOM,
	RPC_QUANTITY,
	PRODUCT_RPC_NAME,
	RPC_START_DATE,
	RPC_END_DATE,
	SUBSCRIPTION_NUMBER,
	SUBSCRIPTION_STATUS,
	RPC_NUMBER,
	MARKETING_SCHEDULE_CODE,
	MARKETING_SCHEDULE_NAME,
	GLOBAL_PARENT,
	TIER_COVERAGE,
	TOTAL_BRV_ACV_USDB,
	ID,
	"License Compliance Summary Name",
	"Created Date",
	"Last Modified Date",
	"Compliance Quoted Amount USD",
	"Resulting Opportunity TCV Amount USD",
	"Resulting Opportunity ACV Amount USD",
	"Resulting Opportunity",
	"Usage Reporting Owner",
	"Usage Reporting Program Status",
	"Usage Status",
	"Usage Reporting Program Type",
	"Usage Reporting Target Quarter",
	"Analysis Date",
	"LCS ID",
	"From LCU?",
	"Multiple CSNs?",
	ACCOUNT_ID,
	"Fiscal Year",
	"Fiscal Period",
	"Fiscal Quarter",
	"stage",
	"Forecast Category",
	"Opportunity ID",
	"Current On-Prem ARR",
	"Current SaaS ARR",
	"Current Total ARR",
	"Prior On-Prem ARR",
	"Prior SaaS ARR",
	"Prior Total ARR",
	CMI,
	CMI_PERCENTAGE,
	"LCD_License Compliance ID",
	"LCD_LCD ID",
	"LCD_LC Summary",
	"LCD_Analysis Version",
	LCD_CMI,
	"LCD_Tier Sales Area",
	"LCD_Address 1 Country",
	"LCD_Units Owned",
	"LCD_Request Sent",
	"LCD_Usage Results",
	"LCD_Analysis Date",
	"LCD_Analysis Delta",
	"LCD_Analysis Results",
	"LCD_Exclude Reason",
	"LCD_Smart Number",
	"LCD_Product Name",
	"LCD_Product Family",
	"LCD_Product Line",
	LCD_UOM,
	CMI_YOY_PERCENT
) as 
WITH BASE_DATA AS
(SELECT
		DISTINCT adjusted_csn,
		ADJUSTED_CSN_NAME,
		INSTALL_COMPANY_NAME,
		INSTALL_COMPANY_COUNTRY,
		INSTALL_SALES_REGION,
		PAM_DBA,
		RENEWAL_REP,
		BRV_TCV_USDB,
		BRV_ACV_USDB,
		ERV_TCV_USDB,
		ERV_ACV_USDB,
        INDUSTRY_BY_CSN,
        LTV_ACV_USDB,
        LTV_TCV_USDB,
        LAST_BOOKING_DATE,
        TERM_START_DATE,
        TERM_END_DATE,
        PRODUCT_BUSINESS_UNIT,
        PRODUCT_FAMILY,
        PRODUCT_NAME,
        RPC_UOM,
        RPC_QUANTITY,
        PRODUCT_RPC_NAME,
        RPC_START_DATE,
        RPC_END_DATE,
        subscription_number,
        subscription_status,
        rpc_number,
        marketing_schedule_code,
        marketing_schedule_name,
        acc.GLOBAL_PARENT,
        acc."Tier Coverage",
        sum(BRV_ACV_USDB) over(partition by adjusted_csn order by adjusted_csn) as total_brv_acv_usdb
FROM UMDB_BMCOANDS_PRD.ADMIN.VW_GROWLIST  gr
LEFT JOIN (SELECT DISTINCT "Account CSN",b."Organization Name" as GLOBAL_PARENT,sa."Tier Coverage" from UMDB_BMCOANDS_PRD.ADMIN.SFDC_ACCOUNT sa
LEFT JOIN UMDB_BMCOANDS_PRD.ADMIN.SFDC_GSM_ORGANIZATION b ON b.ID = SA."Global Parent") acc
on gr.adjusted_csn=acc."Account CSN"
WHERE UPPER(PRODUCT_BUSINESS_UNIT) IN ('DBA')
      AND UPPER(PRODUCT_FAMILY) = ('CONTROL-M')
      /*AND UPPER(PRODUCT_NAME) IN ('CONTROL-M PLATFORM','CONTROL-M')
      AND (RPC_UOM LIKE 'per task%' or RPC_UOM LIKE 'per MIPS%' or RPC_UOM in ('per average task'))
QUALIFY sum(BRV_ACV_USDB) over(partition by adjusted_csn order by adjusted_csn)>=5000*/
),
QuarterMapping AS (
    -- Shift current date back 1 quarter to find the 'completed' period
    SELECT DATEADD(quarter, -1, CURRENT_DATE()) AS anchor_date
),
FISCAL_YEAR_CAL AS
(
SELECT 
    -- Current Last Completed Quarter
    'FY' || RIGHT(YEAR(DATEADD(month, 9, anchor_date)), 2) || 
    ' Q' || QUARTER(DATEADD(month, -3, anchor_date)) AS last_completed_q,
    -- Prior Year Last Completed Quarter
    'FY' || RIGHT(YEAR(DATEADD(month, 9, anchor_date)) - 1, 2) || 
    ' Q' || QUARTER(DATEADD(month, -3, anchor_date)) AS prior_year_q
FROM QuarterMapping
),
GET_ARR AS
(
SELECT           FISCAL_YEAR_QUARTER,
                  CSN,
                  PRODUCT_FAMILY,
                  ARR
                  FROM UMDB_BMCOANDS_PRD.ADMIN.SALES_OPS_ARR 
            where product_family like 'Control%'
            AND FISCAL_YEAR_QUARTER in ((select  last_completed_q from FISCAL_YEAR_CAL) ,(select  prior_year_q from FISCAL_YEAR_CAL) )
),
PRIOR_CURRENT_ARR AS
( SELECT 
    CSN,
    -- Current Quarter Metrics (FY26 Q3)
    SUM(CASE WHEN FISCAL_YEAR_QUARTER = (select  last_completed_q from FISCAL_YEAR_CAl) 
             AND product_family = 'Control-M' THEN ARR ELSE 0 END) AS "Current On-Prem ARR",
    SUM(CASE WHEN FISCAL_YEAR_QUARTER = (select  last_completed_q from FISCAL_YEAR_CAl) 
             AND product_family = 'Control-M SaaS' THEN ARR ELSE 0 END) AS "Current SaaS ARR",
    SUM(CASE WHEN FISCAL_YEAR_QUARTER = (select  last_completed_q from FISCAL_YEAR_CAl) 
             THEN ARR ELSE 0 END) AS "Current Total ARR",
    -- Prior Year Metrics (FY25 Q3)
    SUM(CASE WHEN FISCAL_YEAR_QUARTER = (select  prior_year_q from FISCAL_YEAR_CAL) 
             AND product_family = 'Control-M' THEN ARR ELSE 0 END) AS "Prior On-Prem ARR",
    SUM(CASE WHEN FISCAL_YEAR_QUARTER = (select  prior_year_q from FISCAL_YEAR_CAL) 
             AND product_family = 'Control-M SaaS' THEN ARR ELSE 0 END) AS "Prior SaaS ARR",
    SUM(CASE WHEN FISCAL_YEAR_QUARTER = (select  prior_year_q from FISCAL_YEAR_CAL) 
             THEN ARR ELSE 0 END) AS "Prior Total ARR"
FROM GET_ARR 
GROUP BY 1
),
final_data AS
(SELECT DISTINCT bd.adjusted_csn,
                bd.ADJUSTED_CSN_NAME,
                bd.INSTALL_COMPANY_NAME,
                bd.INSTALL_COMPANY_COUNTRY,
                bd.INSTALL_SALES_REGION,
                COALESCE(bd.PAM_DBA,'') AS "PAM_DBA",
                bd.RENEWAL_REP,
                ROUND(ZEROIFNULL(bd.BRV_TCV_USDB),2) AS "BRV_TCV_USDB",
                ROUND(ZEROIFNULL(bd.BRV_ACV_USDB),2) AS "BRV_ACV_USDB",
                ROUND(ZEROIFNULL(bd.ERV_TCV_USDB),2) AS "ERV_TCV_USDB",
                ROUND(ZEROIFNULL(bd.ERV_ACV_USDB),2) AS "ERV_ACV_USDB",
                bd.INDUSTRY_BY_CSN,
                ROUND(ZEROIFNULL(bd.LTV_ACV_USDB),2) AS "LTV_ACV_USDB",
                ROUND(ZEROIFNULL(bd.LTV_TCV_USDB),2) AS "LTV_TCV_USDB",
                TO_DATE(bd.LAST_BOOKING_DATE) AS LAST_BOOKING_DATE,
                TO_DATE(bd.TERM_START_DATE) AS TERM_START_DATE,
                TO_DATE(bd.TERM_END_DATE) AS TERM_END_DATE,
                bd.PRODUCT_BUSINESS_UNIT,
                bd.PRODUCT_FAMILY,
                bd.PRODUCT_NAME,
                bd.RPC_UOM,
                bd.RPC_QUANTITY,
                bd.PRODUCT_RPC_NAME,
                TO_DATE(bd.RPC_START_DATE) AS "RPC_START_DATE",
                TO_DATE(bd.RPC_END_DATE) AS "RPC_END_DATE",
                bd.subscription_number,
                bd.subscription_status,
                bd.rpc_number,
                bd.marketing_schedule_code,
                bd.marketing_schedule_name,
                bd.GLOBAL_PARENT, 
                bd."Tier Coverage" as TIER_COVERAGE,
                ROUND(ZEROIFNULL(bd.total_brv_acv_usdb),2) AS total_brv_acv_usdb,
                COALESCE(sv."ID",'') AS "ID",
                COALESCE(sv."License Compliance Summary Name",'') AS "License Compliance Summary Name",
                TO_DATE(sv."Created Date") AS "Created Date",
                TO_DATE(sv."Last Modified Date") AS "Last Modified Date",
                --COALESCE(sv."Account Name",'') AS "Account Name",
                --COALESCE(sv."Account CSN",'') AS "Account CSN",
                ROUND(ZEROIFNULL(sv."Compliance Quoted Amount USD"),2) AS "Compliance Quoted Amount USD",
                ROUND(ZEROIFNULL(sv."Resulting Opportunity TCV Amount USD"),2) AS "Resulting Opportunity TCV Amount USD",
                ROUND(ZEROIFNULL(sv."Resulting Opportunity ACV Amount USD"),2) AS "Resulting Opportunity ACV Amount USD",
                COALESCE(sv."Resulting Opportunity",'') AS "Resulting Opportunity" ,
                COALESCE(sv."Usage Reporting Owner",'') AS "Usage Reporting Owner",
                COALESCE(sv."Usage Reporting Program Status",'') AS "Usage Reporting Program Status",
                COALESCE(trim(split(sv."Usage Reporting Program Status",'-')[0]),'') as "Usage Status",
                COALESCE(sv."Usage Reporting Program Type",'') AS "Usage Reporting Program Type" ,
                COALESCE(sv."Usage Reporting Target Quarter",'') AS "Usage Reporting Target Quarter",
                sv."Analysis Date",
                COALESCE(sv."LCS ID",'') AS "LCS ID",
                COALESCE(TO_VARCHAR(sv."From LCU?"), '') AS "From LCU?",
                COALESCE(TO_VARCHAR(sv."Multiple CSNs?"), '') AS "Multiple CSNs?",
                COALESCE(sv.account_id,'') AS "account_id",
                sv."Fiscal Year" AS "Fiscal Year",
	            sv."Fiscal Period" AS "Fiscal Period",
	            sv."Fiscal Quarter" AS "Fiscal Quarter",
	            COALESCE(sv."stage",'') AS "stage",
	            COALESCE(sv."Forecast Category",'') AS "Forecast Category",
	            COALESCE(sv."Opportunity ID",'') AS "Opportunity ID",
                pc."Current On-Prem ARR",
                pc."Current SaaS ARR",
                pc."Current Total ARR",
                pc."Prior On-Prem ARR",
                pc."Prior SaaS ARR",
                pc."Prior Total ARR",
                COALESCE(sv."CMI",'') AS "CMI",
CASE
    -- Pattern: s/0.7 -> 70%
    WHEN sv."CMI" LIKE 's/%' THEN
        TO_VARCHAR(
            ROUND(CAST(REGEXP_SUBSTR(sv."CMI", '/([0-9.]+)', 1, 1, 'e') AS NUMBER(10,2)) * 100,0)
        ) || '%'
    -- Pattern: d365/0.1-0.4/0 -> 40%
    -- Pattern: d/1.0-1.0/0 -> 100%
    WHEN sv."CMI" LIKE '%/%-%/%' OR sv."CMI" LIKE 'd/%' THEN
        TO_VARCHAR(
            ROUND(CAST(REGEXP_SUBSTR(sv."CMI", '-([0-9.]+)', 1, 1, 'e') AS NUMBER(10,2)) * 100,0)
        ) || '%'
    ELSE NULL 
    END AS CMI_PERCENTAGE,
    COALESCE(cv."License Compliance ID",'') AS "LCD_License Compliance ID",
    --COALESCE(cv."Account Name",'') AS "LCD_Account Name",
    COALESCE(cv."LCD ID",'') AS "LCD_LCD ID",
    COALESCE(cv."LC Summary",'') AS "LCD_LC Summary",
    COALESCE(cv."Analysis Version",'') AS "LCD_Analysis Version",
    COALESCE(cv."CMI",'') AS "LCD_CMI",
    COALESCE(cv."Tier Sales Area",'') AS "LCD_Tier Sales Area",
    COALESCE(cv."Address 1 Country",'') AS "LCD_Address 1 Country",
    ZEROIFNULL(cv."Units Owned") AS "LCD_Units Owned",
    cv."Request Sent" AS "LCD_Request Sent",
    cv."Usage Results" AS "LCD_Usage Results",
    cv."Analysis Date" AS "LCD_Analysis Date",
    cv."Analysis Delta" AS "LCD_Analysis Delta",
    COALESCE(cv."Analysis Results",'') AS "LCD_Analysis Results",
    COALESCE(cv."Exclude Reason",'') AS "LCD_Exclude Reason",
    COALESCE(cv."Smart Number",'') AS "LCD_Smart Number",
    COALESCE(cv."Product Name",'') AS "LCD_Product Name",
    COALESCE(cv."Product Family",'') AS "LCD_Product Family",
    COALESCE(cv."Product Line",'')AS "LCD_Product Line",
    COALESCE(cv."UOM",'') AS "LCD_UOM"
FROM BASE_DATA bd
LEFT JOIN (SELECT * FROM UMDB_BMCOANDS_PRD.ADMIN.SFDC_LICENSE_COMPLIANCE_DETAIL_VIEW 
            WHERE UPPER(UOM) IN ('PER TASK',
    'PER MANAGED ASSET - CONTROL-M SERVER ENDPOINT',
    'PER CPU - FULL CAPACITY',
    'PER MIPS',
    'PER MANAGED ASSET - SERVER ENDPOINT')
     AND "Product Name" IN ('Control-M Platform','Control-M Platform PW','Control-M Suite'))cv
on cv."Account CSN"=bd.adjusted_csn
LEFT JOIN (SELECT * FROM UMDB_BMCOANDS_PRD.ADMIN.SFDC_LICENSE_COMPLIANCE_SUMMARY_VIEW
            WHERE UPPER("Usage Reporting Program Type") like 'CONTROL%'
            AND "Usage Reporting Program Status" != 'Excluded from Cycle - Not Analyzed')sv
on cv."License Compliance ID"=sv.id
LEFT JOIN PRIOR_CURRENT_ARR pc
on pc.CSN=bd.adjusted_csn
)
,
CAL_CMI_YOY_PERCENT AS
(
  SELECT DISTINCT
  adjusted_csn,
  "Analysis Date",
    CASE
        WHEN"CMI" LIKE 's/%' THEN
            ROUND(CAST(REGEXP_SUBSTR("CMI", '/([0-9.]+)', 1, 1, 'e') AS NUMBER(10,4)),4)*100
    
        WHEN "CMI" LIKE '%/%-%/%' OR "CMI" LIKE 'd/%' THEN
            ROUND(CAST(REGEXP_SUBSTR("CMI", '-([0-9.]+)', 1, 1, 'e') AS NUMBER(10,4)),4)*100
    
        ELSE NULL
     END AS CMI_DECIMAL,
    LAG(CMI_DECIMAL) OVER (
          PARTITION BY adjusted_csn
          ORDER BY "Analysis Date"
      ) AS PRIOR_CMI

    ,( (CMI_DECIMAL -
    LAG(CMI_DECIMAL) OVER (
        PARTITION BY adjusted_csn
        ORDER BY "Analysis Date"
    )
  )
  /
  NULLIF(
      LAG(CMI_DECIMAL) OVER (
          PARTITION BY adjusted_csn
          ORDER BY "Analysis Date"
      ),
      0
  ))*100 AS CMI_YOY_PERCENT
FROM (select distinct adjusted_csn,"Analysis Date","CMI" from  final_data where "Analysis Date" is not null)
)
SELECT distinct
                    fd.adjusted_csn,
                ADJUSTED_CSN_NAME,
                INSTALL_COMPANY_NAME,
                INSTALL_COMPANY_COUNTRY,
                INSTALL_SALES_REGION,
                "PAM_DBA",
                RENEWAL_REP,
                "BRV_TCV_USDB",
                "BRV_ACV_USDB",
                 "ERV_TCV_USDB",
                "ERV_ACV_USDB",
                INDUSTRY_BY_CSN,
                "LTV_ACV_USDB",
                "LTV_TCV_USDB",
                LAST_BOOKING_DATE,
              TERM_START_DATE,
                TERM_END_DATE,
                PRODUCT_BUSINESS_UNIT,
                PRODUCT_FAMILY,
                PRODUCT_NAME,
                RPC_UOM,
                RPC_QUANTITY,
                PRODUCT_RPC_NAME,
                "RPC_START_DATE",
                 "RPC_END_DATE",
                subscription_number,
                subscription_status,
                rpc_number,
                marketing_schedule_code,
                marketing_schedule_name,
                GLOBAL_PARENT,
                TIER_COVERAGE,--
                 total_brv_acv_usdb,
                "ID",
                "License Compliance Summary Name",
                "Created Date",
                 "Last Modified Date",
                --COALESCE(sv."Account Name",'') AS "Account Name",
                --COALESCE(sv."Account CSN",'') AS "Account CSN",
                "Compliance Quoted Amount USD",
                "Resulting Opportunity TCV Amount USD",
                 "Resulting Opportunity ACV Amount USD",
                 "Resulting Opportunity" ,
                "Usage Reporting Owner",
                "Usage Reporting Program Status",
                 "Usage Status",
                 "Usage Reporting Program Type" ,
                "Usage Reporting Target Quarter",
                fd."Analysis Date",
                "LCS ID",
                "From LCU?",
                "Multiple CSNs?",
                "account_id",
                 "Fiscal Year",
	            "Fiscal Period",
	             "Fiscal Quarter",
	            "stage",
	             "Forecast Category",
	             "Opportunity ID",
                "Current On-Prem ARR",
                "Current SaaS ARR",
                "Current Total ARR",
                "Prior On-Prem ARR",
                "Prior SaaS ARR",
                "Prior Total ARR",
                 fd."CMI",
             CMI_PERCENTAGE,
    "LCD_License Compliance ID",
"LCD_LCD ID",
     "LCD_LC Summary",
    "LCD_Analysis Version",
     "LCD_CMI",
   "LCD_Tier Sales Area",
    "LCD_Address 1 Country",
    "LCD_Units Owned",
  "LCD_Request Sent",
"LCD_Usage Results",
    "LCD_Analysis Date",
    "LCD_Analysis Delta",
    "LCD_Analysis Results",
    "LCD_Exclude Reason",
    "LCD_Smart Number",
   "LCD_Product Name",
    "LCD_Product Family",
    "LCD_Product Line",
     "LCD_UOM",
     cc.CMI_YOY_PERCENT
FROM final_data fd
left join CAL_CMI_YOY_PERCENT cc
ON fd.adjusted_csn=cc.adjusted_csn and fd."Analysis Date"=cc."Analysis Date"
--GRANT SELECT ON VIEW UMDB_BMCOANDS_PRD.ADMIN.TABLEAU_DBA_ON_PREM_LICENSE_COMPLIANCE_VIEW TO ROLE READGRP_UMDB_CS_ALL_PRD
;