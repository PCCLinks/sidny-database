DELIMITER //
DROP PROCEDURE IF EXISTS spBillingGenerateAttendanceBilling //
CREATE PROCEDURE spBillingGenerateAttendanceBilling(paramBillingStartDate date, paramCreatedBy varchar(45))
BEGIN
	DECLARE paramBillingCycleId INT;
    DECLARE paramBillingReportId INT;
    DECLARE paramProgramYear varchar(25);
    
    SELECT billingCycleId, ProgramYear INTO paramBillingCycleId, paramProgramYear
    FROM billingCycle
    WHERE billingStartDate = paramBillingStartDate
		and billingType = 'Attendance';
    
    call spBillingUpdateAttendanceBilling(paramBillingStartDate, paramCreatedBy, 0);
            
	INSERT INTO billingReport(billingCycleID, CreatedBy) VALUES(paramBillingCycleId, paramCreatedBy);
    
    SET paramBillingReportId = last_insert_id();

    INSERT INTO sidny.billingReportAttendance
		(BillingReportId,
		ContactID,
		BannerGNumber,
		FirstName,
		LastName,
		Program,
		SchoolDistrict,
		EntryDate,
		ExitDate,
		June,
		July,
		August,
		September,
		October,
		November,
		December,
		January,
		February,
		March,
		April,
		May,
		TotalAttendance,
		TotalEnrollment,
		DateCreated,
		CreatedBy)
	select paramBillingReportId
		,contactId
		,bannerGNumber
        ,firstname
        ,lastname
        ,program
        ,schoolDistrict
        ,MIN(billingStartDate) entryDate
        ,exitDateGroupBy 
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 6 then billedAmount end,0),1)) Jun
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 7 then billedAmount end,0),1)) Jul
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 8 then billedAmount end,0),1)) Aug
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 9 then billedAmount end,0),1)) Sept
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 10 then billedAmount end,0),1)) Oct
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 11 then billedAmount end,0),1)) Nov
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 12 then billedAmount end,0),1)) Dcm
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 1 then billedAmount end,0),1)) Jan
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 2 then billedAmount end,0),1)) Feb
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 3 then billedAmount end,0),1)) Mar
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 4 then billedAmount end,0),1)) Apr
		,SUM(ROUND(IFNULL(case when month(billingStartDate) = 5 then billedAmount end,0),1)) May
		,SUM(ROUND(IFNULL(billedAmount,0),1)) Attnd
        ,SUM(IFNULL(Enrollment,0)) Enrl
        ,now()
        ,paramCreatedBy
	from ( select bsp.firstname, bsp.lastname, bs.bannerGNumber, bs.contactId
			,bs.billingStudentId, bs.billingStartDate, bs.ExitDate
            ,(select min(exitDate) from billingStudent where billingStartDate >= bs.billingStartDate and bannerGNumber = bs.bannerGNumber) exitDateGroupBy
			,bs.billingEndDate, bs.enrolledDate
			,COALESCE(bs.adjustedDaysPerMonth,bs.maxDaysPerMonth) Enrollment, sd.schooldistrict, program
			,bs.GeneratedBilledAmount BilledAmount
		from billingStudent bs
			join billingStudentProfile bsp on bs.contactId = bsp.contactId
			join keySchoolDistrict sd on bs.DistrictID = sd.keySchoolDistrictID
		where bs.term in (select term from bannerCalendar where programYear = paramProgramYear)
			and bs.billingStartDate <= paramBillingStartDate
			and bs.Program like '%attendance%'
            and includeFlag = 1
            and GeneratedBilledAmount != 0
		) data
	group by lastname, firstname, bannerGNumber, exitDateGroupBy, schooldistrict, program
	order by lastname, firstname;
            
	UPDATE billingCycle
    SET LatestBillingReportID = paramBillingReportId
    WHERE billingCycleId = paramBillingCycleId;
END