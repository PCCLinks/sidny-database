DELIMITER //
DROP PROCEDURE IF EXISTS spPopulateTmpReportActiveDuring//
CREATE PROCEDURE spPopulateTmpReportActiveDuring(IN paramStartDate datetime, IN paramEndDate datetime, IN paramProgram varchar(50), IN paramProgramDetail varchar(50), IN paramSchoolDistrictID INT)
BEGIN

	/* Used by the SIDNY application, and could also be used for reporting
    /  Populates the table tmpReportActiveDuring
    
	/  Gets all the contacts that are active within this time period specified
    /  i.e. the entry date is before the end date and the exit date is after the start date
    /  12/13/2017 Arlette Slachmuylder */
    
    #get the source data
    call spPopulateTmpEnrollExit(0);
    
    #determine the lastest row per contact within the time 
    #period specified
    #EnrollExit table built with ID in order of status
    DROP TEMPORARY TABLE IF EXISTS sptmp_LatestInRange;
	CREATE TEMPORARY TABLE sptmp_LatestInRange AS  
    SELECT contactID, max(ID) ID
	FROM sptmp_EnrollExit
    WHERE (
			(exitDate is null and enrolledDate < paramEndDate)
				OR (exitDate >= paramStartDate and enrolledDate < paramEndDate)
			)
		AND (program = paramProgram or paramProgram = "0")
        AND (programDetail = paramProgramDetail or paramProgramDetail = "0")
		AND (keySchoolDistrictID = paramSchoolDistrictId or paramSchoolDistrictID = 0)
	GROUP BY contactID;

	DROP TABLE IF EXISTS tmpReportActiveDuring;
	CREATE TABLE tmpReportActiveDuring AS
	select  contact.bannerGNumber 'Banner G Number'
		, contact.firstName 'First Name'
		, contact.lastName 'Last Name'
		, contact.emailPCC 'Email PCC'
		, contact.emailAlt 'Email Alternate'
		, tmpEnrollExit.schoolDistrict as 'School District During Timeframe' -- district during specified timeframe
		, contact.ssid 'Student District Number'
		, date_format(tmpEnrollExit.enrolledDate,'%Y-%m-%d') as 'Last Enroll in Timeframe' 
		, date_format(tmpEnrollExit.exitDate,'%Y-%m-%d') as 'Last Exit in Timeframe'
		, tmpEnrollExit.ProgramDetail 'Program During Timeframe'
        , tmpEnrollExit.Coach 'Coach During Timeframe'
		, tmpCurrentEnrollExit.CurrentStatus 'Current Status'
		, date_format(tmpCurrentEnrollExit.enrolledDate,'%Y-%m-%d') as 'Current Enroll Date' 
		, date_format(tmpCurrentEnrollExit.exitDate,'%Y-%m-%d') as 'Current Exit Date'
        , contact.lastHSAttended 'Last HS Attended'
	from contact
		join sptmp_EnrollExit tmpEnrollExit on contact.contactId = tmpEnrollExit.contactId
        join sptmp_LatestInRange
            on tmpEnrollExit.ID = sptmp_LatestInRange.ID
        join sptmp_CurrentEnrollExit tmpCurrentEnrollExit 
			on contact.contactID = tmpCurrentEnrollExit.contactID;

END//
DELIMITER ;
