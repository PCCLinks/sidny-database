DELIMITER //
DROP PROCEDURE IF EXISTS spPopulateTmpReportEnrolledDuring//
CREATE PROCEDURE spPopulateTmpReportEnrolledDuring(IN paramStartDate datetime, IN paramEndDate datetime, IN paramProgram varchar(50), IN paramProgramDetail varchar(50), IN paramSchoolDistrictID INT)
BEGIN

	/* Used by the SIDNY application, and could also be used for reporting
    /  Populates the table tmpReportEnrolledDuring
    
	/  Gets all the contacts were enrolled during the time period specified
    /  Also gets the current enrolled dates and status
    /  12/13/2017 Arlette Slachmuylder */
    
    call spPopulateTmpEnrollExit(0);


    #determine the first row per contact within the time 
    #period specified
    #EnrollExit table built with ID in order of status
    DROP TEMPORARY TABLE IF EXISTS sptmp_FirstInRange;
	CREATE TEMPORARY TABLE sptmp_FirstInRange AS  
    SELECT contactID, min(ID) ID
	FROM sptmp_EnrollExit
    WHERE  (program = paramProgram or paramProgram = "0")
		and (programDetail = paramProgramDetail or paramProgramDetail = "0")
		and enrolledDate >= paramStartDate
		and enrolledDate <= paramEndDate  
        and (keySchoolDistrictID = paramSchoolDistrictID or paramSchoolDistrictID = 0)
	GROUP BY contactID;

	DROP TABLE IF EXISTS tmpReportEnrolledDuring;
    
	CREATE TABLE tmpReportEnrolledDuring AS
	-- pull contactIDs with an enroll during specified timeframe with reason
	select contact.bannerGNumber 'Banner G Number'
		, contact.firstName 'First Name'
		, contact.lastName 'Last Name'
		, contact.emailPCC 'Email PCC'
		, contact.emailAlt 'Email Alternate'
		, tmpEnrollExit.schoolDistrict as 'School District During Timeframe' -- district during specified timeframe
		, contact.ssid 'Student District Number'
		, date_format(tmpEnrollExit.enrolledDate,'%Y-%m-%d') as 'First Enroll Date Of Timeframe'
		, tmpEnrollExit.ProgramDetail 'Program During Timeframe'
		, tmpCurrentEnrollExit.CurrentStatus 'Current Status'    
		, date_format(tmpCurrentEnrollExit.EnrolledDate,'%Y-%m-%d') as 'Current Enroll Date'
		, date_format(tmpCurrentEnrollExit.exitDate,'%Y-%m-%d') as 'Current Exit Date'
		from contact	
			inner join  sptmp_EnrollExit tmpEnrollExit #get the first enrolled date per contact for the specified timeframe
				on contact.contactId = tmpEnrollExit.contactId
            inner join sptmp_FirstInRange
				on tmpEnrollExit.ID = sptmp_FirstInRange.ID                     
			# join to get current enroll status in this program
			inner join sptmp_CurrentEnrollExit tmpCurrentEnrollExit	
				on contact.contactID = tmpCurrentEnrollExit.contactId;

END$$
DELIMITER ;
