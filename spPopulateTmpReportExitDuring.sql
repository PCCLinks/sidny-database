DELIMITER //
DROP PROCEDURE IF EXISTS spPopulateTmpReportExitDuring//
CREATE PROCEDURE spPopulateTmpReportExitDuring(IN paramStartDate datetime, IN paramEndDate datetime, IN paramProgram varchar(50), IN paramProgramDetail varchar(50), IN paramSchoolDistrictID INT, IN paramResourceSpecialistID INT)
BEGIN

	/* Used by the SIDNY application, and could also be used for reporting
    /  Populates the table tmpReportExitDuring
    
	/  Gets all the contacts who exited during the time period specified
    /  Also gets the current enrolled dates and status
    /  12/13/2017 Arlette Slachmuylder */
    
	call spPopulateTmpEnrollExit(0);

    #determine the lastest row per contact within the time 
    #period specified
    #EnrollExit table built with ID in order of status
    DROP TEMPORARY TABLE IF EXISTS sptmp_LastInRange;
	CREATE TEMPORARY TABLE sptmp_LastInRange AS  
    SELECT contactID, max(ID) ID
	FROM sptmp_EnrollExit
    WHERE (program = paramProgram or paramProgram = "0")
		and (programDetail = paramProgramDetail or paramProgramDetail = "0")
		and exitDate >= paramStartDate
		and exitDate <= paramEndDate   
        and (keySchoolDistrictID = paramSchoolDistrictID or paramSchoolDistrictID = 0)
		and (keyResourceSpecialistID = paramResourceSpecialistID or paramResourceSpecialistID = 0)
	GROUP BY contactID;

	DROP TABLE IF EXISTS tmpReportExitDuring;
    
	CREATE TABLE tmpReportExitDuring AS
	-- pull contactIDs with an exit during specified timeframe with reason
	select contact.bannerGNumber 'Banner G Number'
		, contact.firstName 'First Name'
		, contact.lastName 'Last Name'
		, contact.emailPCC 'Email PCC'
		, contact.emailAlt 'Email Alternate'
		, tmpEnrollExit.schoolDistrict as 'School District During Timeframe' -- district during specified timeframe
		, contact.ssid 'Student District Number'
		, tmpEnrollExit.ExitReason as 'Exit Reason'
		, tmpEnrollExit.SecondaryReason as 'Secondary Exit Reason'
		, tmpEnrollExit.ExitNote as 'Exit Note'
		, contact.dob 'Date of Birth'
        , tmpEnrollExit.Coach 'Coach During Timeframe'
		, date_format(tmpEnrollExit.ExitDate,'%Y-%m-%d') as 'Last Exit Date of Timeframe'
		, tmpEnrollExit.programDetail as 'Program During Timeframe'
		, tmpCurrentEnrollExit.CurrentStatus 'Current Status' 
		, date_format(tmpCurrentEnrollExit.EnrolledDate,'%Y-%m-%d') as 'Current Enroll Date'
		, date_format(tmpCurrentEnrollExit.exitDate,'%Y-%m-%d') as 'Current Exit Date'
        , riskFactors 'Risk Factors'
	from contact	
		inner join sptmp_EnrollExit tmpEnrollExit
			on contact.contactID = tmpEnrollExit.contactID
		inner join sptmp_LastInRange
			on sptmp_LastInRange.ID = tmpEnrollExit.ID
		inner join sptmp_CurrentEnrollExit tmpCurrentEnrollExit	
			on contact.contactID = tmpCurrentEnrollExit.contactId
		left outer join (select contactID, GROUP_CONCAT(riskFactorName ORDER BY riskFactorName asc) riskFactors
						 from contactRiskFactor crf
								join riskFactor rf on crf.riskFactorID = rf.riskFactorID
						 group by contactID) riskFactors
				on contact.contactID = riskFactors.contactID;
            
END$$
DELIMITER ;
