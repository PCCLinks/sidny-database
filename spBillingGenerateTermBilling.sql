DELIMITER //
DROP PROCEDURE IF EXISTS spBillingGenerateTermBilling//
CREATE PROCEDURE spBillingGenerateTermBilling(paramTerm int(11), paramCreatedBy varchar(45))
BEGIN

	DECLARE paramBillingCycleId INT;
    DECLARE paramBillingReportID INT;
    DECLARE paramProgramYear varchar(25);
    DECLARE paramMaxDaysPerYear INT;
    DECLARE paramTermLoop INT;
    
    CALL spBillingUpdateTermBilling(paramTerm, paramCreatedBy);
    
    SELECT BillingCycleId, ProgramYear, MaxBillableDaysPerYear
		INTO paramBillingCycleId, paramProgramYear, paramMaxDaysPerYear
    FROM billingCycle
    WHERE term = paramTerm
		and billingType = 'Term';
        
	INSERT INTO billingReport(billingCycleID, CreatedBy) VALUES(paramBillingCycleId, paramCreatedBy);
    
    SET paramBillingReportId = last_insert_id();

	DROP TEMPORARY TABLE IF EXISTS sptmp_terms;
	CREATE TEMPORARY TABLE sptmp_terms AS
    SELECT Term
    FROM bannerCalendar 
    WHERE ProgramYear = paramProgramYear;
    
    SELECT min(Term)
		INTO paramTermLoop
	FROM sptmp_terms;
    
    #rerun previous terms to catch corrections
    WHILE paramTermLoop < paramTerm DO
		call spBillingUpdateTermBilling(paramTermLoop, paramCreatedBy);
        
		SELECT min(Term)
			INTO paramTermLoop
		FROM sptmp_terms
        WHERE Term > paramTermLoop;
	END WHILE;
        
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
		,bs.exitDateGroupBy
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
		,SUM(bsOther.Days) OtherDaysBilled
		,SUM(bs.Credits+bs.CreditsOver) FYTotalNoOfCredits
		,SUM(bs.Credits) FYMaxTotalNoOfCredits
		,SUM(bs.Days+bs.DaysOver) + IFNULL(bsOther.Days,0) FYTotalNoOfDays
		,CASE WHEN (SUM(bs.Days) + IFNULL(bsOther.Days,0)) > paramMaxDaysPerYear THEN paramMaxDaysPerYear ELSE (SUM(bs.Days) + IFNULL(bsOther.Days,0)) END FYMaxTotalNoOfDays
        ,paramCreatedBy
	FROM (SELECT bsSub.contactId, bsSub.billingStudentId, firstname, lastname, bsSub.bannerGNumber,
				Term, DistrictID, Program, ExitDate, 
                (select min(exitDate) from billingStudent where billingStartDate >= bsSub.billingStartDate and bannerGNumber = bsSub.bannerGNumber) exitDateGroupBy,
                billingStartDate, billingEndDate, enrolledDate,
				GeneratedBilledUnits Credits,
				GeneratedOverageUnits CreditsOver,
				GeneratedBilledAmount Days,
				GeneratedOverageAmount DaysOver
			FROM billingStudent bsSub
				JOIN billingStudentProfile bsp on bsSub.contactId = bsp.contactId
				join keySchoolDistrict schooldistrict on bsSub.DistrictID = schooldistrict.keyschooldistrictid
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
	GROUP BY bs.firstname, bs.lastname, bs.exitDateGroupBy, bs.bannergnumber
			,bs.Program
			,schooldistrict.schoolDistrict;
            
	UPDATE billingCycle
    SET LatestBillingReportID = paramBillingReportId
    WHERE billingCycleId = paramBillingCycleId;
END//
DELIMITER ;