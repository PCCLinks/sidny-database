DELIMITER //
DROP PROCEDURE IF EXISTS spUpdateBillingStudentExitData//
CREATE PROCEDURE spUpdateBillingStudentExitData(IN paramContactID int)
BEGIN
	DECLARE paramProgramYearStartDate datetime;

	call spPopulateTmpEnrollExit(paramContactID);
    
	SELECT min(termBeginDate) INTO paramProgramYearStartDate
	FROM bannerCalendar
		join (SELECT max(ProgramYear) ProgramYear
	FROM bannerCalendar
	WHERE termBeginDate <= now()) currentYear on bannerCalendar.ProgramYear = currentYear.ProgramYear;
      
	UPDATE billingStudent
		join sptmp_EnrollExit ee on billingStudent.contactId = ee.contactId
			and billingStudent.enrolledDate = ee.enrolledDate
            and billingStudent.program = ee.programDetail
	SET billingStudent.exitDate = ee.exitDate
    WHERE billingStudent.exitDate IS NULL and ee.exitDate is not null
            and (
				(month(ee.exitDate) between month(billingStartDate) and month(billingEndDate)
					and billingStudent.program not like '%attendance%')
				or (month(ee.exitDate) = month(billingStartDate)
					and billingStudent.program like '%attendance%')
			)
            and billingStudent.BillingStartDate >= paramProgramYearStartDate;
            
	UPDATE billingStudent
		join sptmp_EnrollExit ee on billingStudent.contactId = ee.contactId
			and billingStudent.enrolledDate = ee.enrolledDate
            and billingStudent.program = ee.programDetail
			and billingStudent.billingStudentExitReasonCode IS NULL and ee.exitKeyStatusReasonID is not null
            and billingStudent.BillingStartDate >= paramProgramYearStartDate	
		join keyStatusReason ksr on ee.exitKeyStatusReasonID = ksr.keyStatusReasonID
			and reasonNum in (1,2,3,4,5,6,7,8,9,10,11,12,13,51,52,53)
	SET billingStudent.billingStudentExitReasonCode = reasonNum
    WHERE billingStudent.billingStudentExitReasonCode IS NULL and ksr.reasonNum is not null
             and (
				(month(ee.exitDate) >= month(billingStartDate)
					and month(ee.exitDate) <= month(billingEndDate)
					and billingStudent.program not like '%attendance%')
				or (month(ee.exitDate) = month(billingStartDate)
					and billingStudent.program like '%attendance%')
			)
            and billingStudent.BillingStartDate >= paramProgramYearStartDate;
            
	select bs.billingStudentId
		,date_Format(bs.billingStartDate,'%Y-%m-%d') billingStartDate
        ,date_format(bs.exitDate,'%Y-%m-%d') exitDate
        ,bser.billingStudentExitReasonDescription
		,AdjustedDaysPerMonth
		,date_format(CASE WHEN sidnyEnrollCurrent.ExitDate< paramProgramYearStartDate THEN NULL ELSE sidnyEnrollCurrent.ExitDate END,'%Y-%m-%d') SidnyExitDate
        ,ksrCurrent.reasonText SidnyExitKeyStatusReason
        ,Attendance
		,bs.program
        ,sd.schooldistrict  
        ,bsp.firstname, bsp.lastname, bs.bannerGNumber, bs.exitStatusReasonID
        ,sidnyEnrollCurrent.exitKeyStatusReasonID SidnyExitKeyStatusReasonID
        ,bs.contactId
        ,bs.billingStudentExitReasonCode
        ,sidnyEnrollCurrent.secondaryReason SidnySecondaryReason
        ,IF(length(sidnyEnrollCurrent.exitNote)=0,substring_index(maxComment,'|',-1),sidnyEnrollCurrent.exitNote) SidnyExitNote
		,date_Format(bs.billingEndDate,'%Y-%m-%d') billingEndDate
 	from billingStudent bs
		join (select contactId, max(billingStudentId) maxBillingStudentId from billingStudent maxBSSub WHERE IncludeFlag = 1 GROUP BY contactID) maxBS on bs.billingStudentId = maxBS.maxBillingStudentId
		join billingStudentProfile bsp on bs.contactid = bsp.contactId
		join sptmp_CurrentEnrollExit sidnyEnrollCurrent on bs.contactId = sidnyEnrollCurrent.contactId
        join (select billingStudentId, sum(Attendance) Attendance from billingStudentItem group by billingStudentId) bsi
			on bs.billingStudentId = bsi.billingStudentId
        left outer join billingStudentExitReason bser on bs.BillingStudentExitReasonCode = bser.billingStudentExitReasonCode
		join keySchoolDistrict sd on bs.districtid = sd.keyschooldistrictid
		left outer join keyStatusReason ksrCurrent on sidnyEnrollCurrent.exitKeyStatusReasonID = ksrCurrent.keyStatusReasonID
        left outer join (select contactId, max(concat(commentsId,'|',commentText)) maxComment from comments group by contactId) cmnt
			on cmnt.contactId = bs.contactId
	where bs.billingStartDate >= paramProgramYearStartDate;
        
END//
DELIMITER ;
