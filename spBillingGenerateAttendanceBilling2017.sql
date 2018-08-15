DELIMITER //
DROP PROCEDURE IF EXISTS spBillingGenerateAttendanceBilling2017//
CREATE PROCEDURE spBillingGenerateAttendanceBilling2017(paramBillingStartDate date, paramCreatedBy varchar(45))
BEGIN

	DECLARE paramBillingCycleId INT;
    DECLARE paramMaxDaysPerBillingPeriod INT;
    DECLARE paramBillingReportID INT;
    DECLARE paramProgramYear varchar(25);
    
    SELECT billingCycleId,  MaxBillableDaysPerBillingPeriod, ProgramYear
		INTO paramBillingCycleId, paramMaxDaysPerBillingPeriod, paramProgramYear
    FROM billingCycle
    WHERE billingStartDate = paramBillingStartDate
		and billingType = 'Attendance';
        
	INSERT INTO billingReport(billingCycleID, CreatedBy) VALUES(paramBillingCycleId, paramCreatedBy);
    
    SET paramBillingReportId = last_insert_id();

	update billingStudentItem bsi
		join billingStudent bs on bs.BillingStudentID = bsi.BillingStudentID
		join billingScenarioByCourse bsbc  on bsi.CRN = bsbc.CRN and bs.term = bsbc.term
		join billingScenario bsc on bsbc.billingScenarioId = bsc.billingScenarioId
		join keySchoolDistrict sd on bs.DistrictID = sd.keySchoolDistrictID
	set bsi.Scenario = bsc.billingScenarioName,
		bsi.IndPercent = bsc.IndPercent,
		bsi.SmallPercent = bsc.SmallPercent,
		bsi.InterPercent = bsc.InterPercent,
		bsi.LargePercent = bsc.LargePercent,
        bsi.DateLastUpdated = now(),
        bsi.LastUpdatedBy = paramCreatedBy
	where bsi.includeFlag = 1
		and bs.Program like '%attendance%'
		and bs.billingStartDate = paramBillingStartDate;
        
	/*going to do some stepped updates to help with calculations of max days per month
			   where a month is split between two terms.  In that instance, the later billing start date
			   for the month will have the aggregated number of days between the two terms, and contain
			   the amount billed for the month --->
			 <!--- TODO - repeating where clause -- need better solution --->  */
	update billingStudent
	set maxDaysPerBillingPeriod = paramMaxDaysPerBillingPeriod,
        DateLastUpdated = now(),
        LastUpdatedBy = paramCreatedBy
	where Program like '%attendance%'
		and billingStartDate = paramBillingStartDate;
            
	#updateMaxDaysPerMonth
	update billingStudent
		join (select contactId, max(billingStartDate) billingStartDate, sum(maxDaysPerBillingPeriod) maxDaysPerMonth
			  from billingStudent bsSub
			  where bsSub.Program like '%attendance%'
					and MONTH(bsSub.billingStartDate) = MONTH(paramBillingStartDate)
					and YEAR(bsSub.billingStartDate) = YEAR(paramBillingStartDate)
			  group by contactId
			) bsMonth on billingStudent.contactId = bsMonth.contactId
				and billingStudent.billingStartDate = bsMonth.billingStartDate
	set billingStudent.maxDaysPerMonth = bsMonth.maxDaysPerMonth,
		billingStudent.DateLastUpdated = now(),
        billingStudent.LastUpdatedBy = paramCreatedBy;
    
    #updateWithMonthMaxDaysPerMonth
	update billingStudent
		join
		(
		select billingStudentId
			,sum(ind) + sum(small)*0.333 + sum(inter)*0.222 + sum(large)*0.167 + sum(ind + small + inter + large)*0.0167 BilledAmount
			,sum(small) Small, sum(inter) Inter, sum(Large) Large
		from (
		select bs.billingStudentId
			,bsi.Attendance
			,bsi.Attendance*IFNULL(IndPercent,0) as Ind
			,bsi.Attendance*IFNULL(SmallPercent,0) as Small
			,bsi.Attendance*IFNULL(InterPercent,0) as Inter
			,bsi.Attendance*IFNULL(LargePercent,0) as Large
		from billingStudent bs
			join billingStudentItem bsi on bs.BillingStudentID = bsi.BillingStudentID
			join keySchoolDistrict sd on bs.DistrictID = sd.keySchoolDistrictID
		where bsi.includeFlag = 1
			and bs.Program like '%attendance%'
			and bs.billingStartDate = paramBillingStartDate
			) data
		group by billingStudentId) finalData
	on billingStudent.billingStudentId = finalData.billingStudentId
	set GeneratedBilledAmount  = round(IFNULL(case when BilledAmount > billingStudent.maxDaysPerMonth
													then billingStudent.maxDaysPerMonth
													else BilledAmount end,0),2),
		GeneratedOverageAmount = round(IFNULL(case when BilledAmount > billingStudent.maxDaysPerMonth
													 then BilledAmount - billingStudent.maxDaysPerMonth
													 else 0 end,0),2),
		SmGroupPercent = 0.333,
		InterGroupPercent = 0.222,
		LargeGroupPercent = 0.167,
		CMPercent = 0.0167,
		AdjustedIndHours = case when BilledAmount > billingStudent.maxDaysPerMonth
								then (billingStudent.maxDaysPerMonth -  (0.3497 * Small) - (0.2387 * Inter) - (0.1837 * Large)) / 1.0167
								else NULL
							end,
		DateLastUpdated = now(),
        LastUpdatedBy = paramCreatedBy;
	
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
	select paramBillingReportID
		,contactId
		,bannerGNumber
        ,firstname
        ,lastname
        ,program
        ,schoolDistrict
        ,MIN(billingStartDate) entryDate
        ,MAX(exitdate) exitDate
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
			,bs.billingEndDate, bs.enrolledDate
			,COALESCE(bs.adjustedDaysPerMonth,bs.maxDaysPerMonth) Enrollment, sd.schooldistrict, program
			,COALESCE(bs.PostBillCorrectedBilledAmount, bs.FinalBilledAmount, bs.CorrectedBilledAmount, bs.GeneratedBilledAmount) BilledAmount
		from billingStudent bs
			join billingStudentProfile bsp on bs.contactId = bsp.contactId
			join keySchoolDistrict sd on bs.DistrictID = sd.keySchoolDistrictID
		where bs.term in (select term from bannerCalendar where programYear = paramProgramYear)
			and bs.billingStartDate <= paramBillingStartDate
			and bs.Program like '%attendance%'
            and includeFlag = 1
		) data
	group by lastname, firstname, bannerGNumber, enrolledDate, schooldistrict, program
	order by lastname, firstname;
            
	UPDATE billingCycle
    SET LatestBillingReportID = paramBillingReportId
    WHERE billingCycleId = paramBillingCycleId;
END//
DELIMITER ;
