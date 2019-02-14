DELIMITER //
DROP PROCEDURE IF EXISTS spBillingUpdateTermBilling //
CREATE PROCEDURE spBillingUpdateTermBilling(paramTerm int, paramCreatedBy varchar(45))
BEGIN
	/** This updates billingStudent billing amounts for both new terms 
	 *  and older terms in the same program year
     **/

    DECLARE paramMaxCreditsPerYear INT;
    DECLARE paramMaxDaysPerYear INT;
    DECLARE paramProgramYear varchar(25);
    
    SELECT MaxBillableCreditsPerTerm, MaxBillableDaysPerYear, ProgramYear
		INTO paramMaxCreditsPerYear, paramMaxDaysPerYear, paramProgramYear
    FROM billingCycle
    WHERE term = paramTerm
		and billingType = 'Term';

	DROP TEMPORARY TABLE IF EXISTS sptmp_billingStudent;
	CREATE TEMPORARY TABLE sptmp_billingStudent AS
    select billingStudentId,
		GeneratedBilledUnits,
        GeneratedOverageUnits,
		ROUND(finalData.GeneratedBilledUnits /paramMaxCreditsPerYear*paramMaxDaysPerYear,4) GeneratedBilledAmount,
		ROUND(finalData.GeneratedOverageUnits /paramMaxCreditsPerYear*paramMaxDaysPerYear,4) GeneratedOverageAmount
	from(
		#build data of paramTerm with program ytc
        select bs.billingStudentId,
			CASE WHEN creditYearTotal >= paramMaxCreditsPerYear
				THEN CASE WHEN Overage < 0 THEN 0 Else Overage END
				ELSE creditCurrentCycleTotal
				END GeneratedBilledUnits,
			creditCurrentCycleTotal -
				(CASE WHEN creditYearTotal >= paramMaxCreditsPerYear
					  THEN CASE WHEN Overage < 0 THEN 0 Else Overage END
					  ELSE creditCurrentCycleTotal END)
				GeneratedOverageUnits
		from (
			  #pull in program ytd amount in order to calculate overages
			  select max(bsSub.billingStudentId) billingStudentId
                ,Program
				,SUM(bsi.Credits) creditYearTotal
				,SUM(CASE term WHEN paramTerm THEN bsi.Credits ELSE 0 END) creditCurrentCycleTotal
				,paramMaxCreditsPerYear-(SUM(bsi.Credits) - SUM(CASE term WHEN paramTerm THEN bsi.Credits ELSE 0 END)) Overage
			  from billingStudent bsSub
				join billingStudentItem bsi on bsSub.BillingStudentID = bsi.BillingStudentID
				#join keySchoolDistrict schooldistrict on bsSub.DistrictID = schooldistrict.keyschooldistrictid
				where bsi.includeFlag = 1 and bsSub.includeFlag = 1
					and bsSub.Program not like '%attendance%'
					and bsSub.term in (select term from bannerCalendar where ProgramYear = paramProgramYear)
					#need to ensure ytd up until the term parameter value
                    #this procedure is run for already billed terms, in order to find corrections
					and bsSub.term <= paramTerm
				group by bsSub.contactId, bsSub.program) perStudentForYear
			join billingStudent bs
				on perStudentForYear.billingStudentId = bs.billingStudentId
		where bs.term = paramTerm) finalData;

	#only update when data is changed, creates more meaningul DateLastUpdated
	update billingStudent bsToUpdate
		join sptmp_billingStudent tmp
			on bsToUpdate.billingStudentId = tmp.billingStudentId
	set bsToUpdate.GeneratedOverageUnits = tmp.GeneratedOverageUnits,
		bsToUpdate.GeneratedBilledUnits =  tmp.GeneratedBilledUnits,
		bsToUpdate.GeneratedBilledAmount = tmp.GeneratedBilledAmount,
		bsToUpdate.GeneratedOverageAmount = tmp.GeneratedOverageAmount,
		bsToUpdate.maxCreditsPerTerm = paramMaxCreditsPerYear,
		bsToUpdate.maxDaysPerYear = paramMaxDaysPerYear,
        bsToUpdate.DateLastUpdated = now(),
        bsToUpdate.LastUpdatedBy = paramCreatedBy
	where bsToUpdate.GeneratedOverageUnits <> tmp.GeneratedOverageUnits
		or bsToUpdate.GeneratedBilledUnits <> tmp.GeneratedBilledUnits
		or bsToUpdate.GeneratedBilledAmount <> tmp.GeneratedBilledAmount
		or bsToUpdate.GeneratedOverageAmount <> tmp.GeneratedOverageAmount
		or bsToUpdate.maxCreditsPerTerm <> paramMaxCreditsPerYear
		or bsToUpdate.maxDaysPerYear <> paramMaxDaysPerYear;
        
END//
DELIMITER ;