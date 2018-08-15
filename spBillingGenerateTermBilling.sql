DELIMITER //
DROP PROCEDURE IF EXISTS spBillingGenerateTermBilling//
CREATE PROCEDURE spBillingGenerateTermBilling(paramTerm int(11), paramCreatedBy varchar(45))
BEGIN

	DECLARE paramBillingCycleId INT;
    DECLARE paramMaxCreditsPerYear INT;
    DECLARE paramMaxDaysPerYear INT;
    DECLARE paramBillingReportID INT;
    DECLARE paramProgramYear varchar(25);
    
    SELECT billingCycleId,  MaxBillableCreditsPerTerm, MaxBillableDaysPerYear, ProgramYear
		INTO paramBillingCycleId, paramMaxCreditsPerYear, paramMaxDaysPerYear, paramProgramYear
    FROM billingCycle
    WHERE term = paramTerm
		and billingType = 'Term';
        
	INSERT INTO billingReport(billingCycleID, CreatedBy) VALUES(paramBillingCycleId, paramCreatedBy);
    
    SET paramBillingReportId = last_insert_id();

	update billingStudent bsToUpdate
		join (
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
			from (select max(bsSub.billingStudentId) billingStudentId
					,SUM(bsi.Credits) creditYearTotal
					,SUM(CASE term WHEN paramTerm THEN bsi.Credits ELSE 0 END) creditCurrentCycleTotal
					,paramMaxCreditsPerYear-(SUM(bsi.Credits) - SUM(CASE term WHEN paramTerm THEN bsi.Credits ELSE 0 END)) Overage
				  from billingStudent bsSub
					join billingStudentItem bsi on bsSub.BillingStudentID = bsi.BillingStudentID
					join keySchoolDistrict schooldistrict on bsSub.DistrictID = schooldistrict.keyschooldistrictid
					where bsi.includeFlag = 1 and bsSub.includeFlag = 1
						and bsSub.Program not like '%attendance%'
						and bsSub.term in (select term from bannerCalendar where ProgramYear = paramProgramYear)
					group by bsSub.contactId) perStudentForYear
				join billingStudent bs
					on perStudentForYear.billingStudentId = bs.billingStudentId
			where bs.term = paramTerm
			)finalData
			on bsToUpdate.billingStudentId = finalData.billingStudentId
	set bsToUpdate.GeneratedOverageUnits = finalData.GeneratedOverageUnits,
		bsToUpdate.GeneratedBilledUnits =  finalData.GeneratedBilledUnits,
		bsToUpdate.GeneratedBilledAmount = ROUND(finalData.GeneratedBilledUnits /paramMaxCreditsPerYear*paramMaxDaysPerYear,4),
		bsToUpdate.GeneratedOverageAmount = ROUND(finalData.GeneratedOverageUnits /paramMaxCreditsPerYear*paramMaxDaysPerYear,4),
		bsToUpdate.maxCreditsPerTerm = paramMaxCreditsPerYear,
		bsToUpdate.maxDaysPerYear = paramMaxDaysPerYear,
        bsToUpdate.DateLastUpdated = now(),
        bsToUpdate.LastUpdatedBy = paramCreatedBy;
        
 	 INSERT INTO sidny.billingReportTerm
		(	BillingReportId,
            contactID,
			bannerGNumber,
			firstName,
			lastName,
			Program,
			SchoolDistrict,
			EntryDate,
			ExitDate,
			SummerCredits,
			SummerDays,
			FallCredits,
			FallCreditsOverage,
			FallDays,
			FallDaysOverage,
			WinterCredits,
			WinterCreditsOverage,
			WinterDays,
			WinterDaysOverage,
			SpringCredits,
			SpringCreditsOverage,
			SpringDays,
			SpringDaysOverage,
			OtherDaysBilled,
			FYTotalNoOfCredits,
			FYMaxTotalNoOfCredits,
			FYTotalNoOfDays,
			FYMaxTotalNoOfDays,
            CreatedBy
		)
	SELECT paramBillingReportId 
        ,bs.contactID
		,bs.bannergnumber
		,bs.firstname
		,bs.lastname
		,bs.Program
		,schooldistrict.schoolDistrict
		,MIN(bs.billingStartDate) EntryDate
		,bs.ExitDate
		,SUM(case when cal.ProgramQuarter = 1 then bs.Credits else 0 end) SummerNoOfCredits
		,SUM(case when cal.ProgramQuarter = 1 then bs.Days else 0 end) SummerNoOfDays
		,SUM(case when cal.ProgramQuarter = 2 then bs.Credits+bs.CreditsOver else 0 end) FallNoOfCredits
		,SUM(case when cal.ProgramQuarter = 2 then bs.CreditsOver else 0 end) FallNoOfCreditsOver
		,SUM(case when cal.ProgramQuarter = 2 then bs.Days+bs.DaysOver else 0 end) FallNoOfDaysOver
		,SUM(case when cal.ProgramQuarter = 2 then bs.DaysOver else 0 end) FallNoOfDaysOver
		,SUM(case when cal.ProgramQuarter = 3 then bs.Credits+bs.CreditsOver else 0 end) WinterNoOfCredits
		,SUM(case when cal.ProgramQuarter = 3 then bs.CreditsOver else 0 end) WinterNoOfCreditsOver
		,SUM(case when cal.ProgramQuarter = 3 then bs.Days+bs.DaysOver else 0 end) WinterNoOfDays
		,SUM(case when cal.ProgramQuarter = 3 then bs.DaysOver else 0 end) WinterNoOfDaysOver
		,SUM(case when cal.ProgramQuarter = 4 then bs.Credits+bs.CreditsOver else 0 end) SpringNoOfCredits
		,SUM(case when cal.ProgramQuarter = 4 then bs.CreditsOver else 0 end) SpringNoOfCreditsOver
		,SUM(case when cal.ProgramQuarter = 4 then bs.Days+bs.DaysOver else 0 end) SpringNoOfDays
		,SUM(case when cal.ProgramQuarter = 4 then bs.DaysOver else 0 end) SpringNoOfDaysOver
		,bsOther.Days OtherDaysBilled
		,SUM(bs.Credits+bs.CreditsOver) FYTotalNoOfCredits
		,SUM(bs.Credits) FYMaxTotalNoOfCredits
		,SUM(bs.Days+bs.DaysOver) + IFNULL(bsOther.Days,0) FYTotalNoOfDays
		,CASE WHEN (SUM(bs.Days) + IFNULL(bsOther.Days,0)) > paramMaxDaysPerYear THEN paramMaxDaysPerYear ELSE (SUM(bs.Days) + IFNULL(bsOther.Days,0)) END FYMaxTotalNoOfDays
        ,paramCreatedBy
	FROM (SELECT billingStudent.contactId, billingStudent.billingStudentId, firstname, lastname, billingStudent.bannerGNumber,
				Term, DistrictID, Program, ExitDate, billingStartDate, billingEndDate, enrolledDate,
				GeneratedBilledUnits Credits,
				GeneratedOverageUnits CreditsOver,
				GeneratedBilledAmount Days,
				GeneratedOverageAmount DaysOver
			FROM billingStudent
				JOIN billingStudentProfile bsp on billingStudent.contactId = bsp.contactId
				join keySchoolDistrict schooldistrict on billingStudent.DistrictID = schooldistrict.keyschooldistrictid
			WHERE term in (select term from bannerCalendar where programYear = paramProgramYear)
				and program not like '%attendance%'
                and includeFlag = 1
                and (GeneratedBilledAmount != 0 OR GeneratedOverageAmount != 0)
         ) bs
		left outer join
			#this allows the combination of credit and attendance programs into a yearly aggregate number
            #once credits are calculated, it is actually equivalent days
			(SELECT contactId, Program, DistrictID, SUM(GeneratedBilledAmount) Days
			FROM billingStudent
			WHERE includeFlag = 1 
				and term in (select term from bannerCalendar where programYear = paramProgramYear)
                and (GeneratedBilledAmount != 0 OR GeneratedOverageAmount != 0)
			group by contactId, Program, DistrictID
			) bsOther
            #joining on where the program is different but the district is the same
			ON bs.contactId = bsOther.contactId and bs.Program != bsOther.Program and bs.DistrictID = bsOther.DistrictID
		join bannerCalendar cal on bs.term = cal.Term
		join keySchoolDistrict schooldistrict on bs.DistrictID = schooldistrict.keyschooldistrictid
	GROUP BY bs.firstname, bs.lastname, bs.exitDate, bs.bannergnumber
			,bs.Program
			,schooldistrict.schoolDistrict
			,bsOther.Days;
            
	UPDATE billingCycle
    SET LatestBillingReportID = paramBillingReportId
    WHERE billingCycleId = paramBillingCycleId;
END//
DELIMITER ;
