CREATE OR REPLACE VIEW UMDB_BMCOANDS_PRD.ADMIN.SFDC_LICENSE_COMPLIANCE_DETAIL_VIEW(
	"License Compliance ID",
	"Account Name",
	"LCD ID",
	"LC Summary",
	"Analysis Version",
	CMI,
	"Tier Sales Area",
	"Current Status",
	"Support Contract ID",
	"LC Tool Account Id",
	"SFDC Opportunity Id",
	"Product Request ID",
	"Opportunty Name",
	"Resulting Opportunity TCV Amount USD",
	"Resulting Opportunity ACV Amount USD",
	"Address 1 Country",
	"Potential License Amount",
	"Case Owner",
	"Units Owned",
	"Request Sent",
	"Usage Results",
	"Analysis Date",
	"Analysis Delta",
	"Exclude Date",
	"Analysis Results",
	"Program Name",
	"Reason",
	"Exclude Reason",
	"Smart Number",
	"Product Name",
	"Product Family",
	"Product Line",
	UOM,
	"Marketing Schedule Name",
	"Support End Date",
	"Account CSN",
	"Tier Coverage"
) as
SELECT slcd."LC Summary" "License Compliance ID", sa."Account Name", slcd."LCD ID", slcd."LC Summary Name" "LC Summary", slcd."Analysis Version", slcd.CMI,
	  sa."Tier Sales Area", slcd."Current Status", slcd."Support Contract ID", slcd."LC Tool Account Id", so."SFDC Opportunity Id", slcd."Product Request ID", so.NAME "Opportunty Name",
	  ot.TCV_TOTAL_PRICE_USD AS "Resulting Opportunity TCV Amount USD", ot.ACV_TOTAL_PRICE_USD AS "Resulting Opportunity ACV Amount USD", sa."Address 1 Country", slcd."Potential License Amount",
	  slcd."Case Owner", slcd."Units Owned",slcd."Request Sent",slcd."Usage Results", slcd."Analysis Date",(slcd."Units Owned" - slcd."Usage Results") "Analysis Delta", slcd."Exclude Date", slcd."Analysis Results",slcd."Program Name",slcd.REASON "Reason",slcd."Exclude Reason",
	  sp."Smart Number / Id" "Smart Number",sp.PRODUCT "Product Name", sp."R&D Product Family" "Product Family", sp."R&D Product Line" "Product Line", slcd.UOM, slcd."Marketing Schedule Name", slcd."Support End Date",
      sa."Account CSN", sa."Tier Coverage"
FROM SFDC_LICENSE_COMPLIANCE_DETAIL slcd INNER JOIN
	 SFDC_LICENSE_COMPLIANCE_SUMMARY slcs ON slcs.ID = slcd."LC Summary" INNER JOIN
	 SFDC_ACCOUNT sa ON sa.ID = slcs.ACCOUNT LEFT OUTER JOIN
	 SFDC_OPPORTUNITY so ON so.ID = slcd.OPPORTUNITY  LEFT OUTER JOIN
	 SFDC_OPPORTUNITY_TOTAL_VIEW ot ON ot.ID = so.ID LEFT OUTER JOIN
	 SFDC_PRODUCT2 sp ON sp.ID = slcd."Product Name"
     --GRANT SELECT ON VIEW UMDB_BMCOANDS_PRD.ADMIN.SFDC_LICENSE_COMPLIANCE_DETAIL_VIEW TO ROLE READGRP_UMDB_CS_ALL_PRD
     ;