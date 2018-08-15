DELIMITER //
DROP PROCEDURE IF EXISTS spPopulateTmpReportGtCApplicant//
CREATE PROCEDURE spPopulateTmpReportGtCApplicant(IN paramStartDate datetime, IN paramEndDate datetime, IN paramSchoolDistrictID INT)
BEGIN
	/* Used by the SIDNY application, and could also be used for reporting
    /  Populates the table tmpReportGtCApplicant
    
	/  Gets all the contacts are in an applicant status as of the time period specified
    /  Only makes sense within the context of the GtC program
    /  12/13/2017 Arlette Slachmuylder */
    
	call spPopulateTmpMaxSchoolDistrict(paramEndDate);

	DROP TABLE IF EXISTS tmpReportGtCApplicant;
    
	CREATE TABLE tmpReportGtCApplicant AS
	-- pull contactIDs with an application status -- without a subsequent status of either enroll, denied, waitlisted, application denied, ytcs
	select contact.bannerGNumber 'Banner G Number'
		, contact.firstName 'First Name'
		, contact.lastName 'Last Name'
		, contact.emailPCC 'Email PCC'
		, contact.emailAlt 'Email Alternate'
		, tmpSD.schoolDistrict as 'School District During Timefram' -- district during specified timeframe
		, contact.ssid 'Student District Number'
		, fnGetProgramName(status.program) as Program
		, date_format(status.statusDate,'%Y-%m-%d') as 'Application Date'
		, contact.hsCreditsEntry 'HS Credits Entry'
		, contact.hsGpaEntry 'HS GPA Enbtry'
		, interviewScore 'Interview Score'
		, evalEssayScore 'Eval Essay Score'
		, evalGrammarScore 'Eval Grammar Score'
		, evalMathScore 'Eval Math Score'
		, evalReadingScore 'Eval Reading Score'
		-- per Adam's request avg the writing scores and average all scores together
		, round(sum(evalGrammarScore + evalEssayScore) / 2,0) as 'Avg Writing Score'
		, round(sum(evalGrammarScore + evalEssayScore + evalReadingScore + evalMathScore) / 4,0) as 'Avg All Scores'
	from contact	
		inner join status 
			on contact.contactID = status.contactID
				and status.keyStatusID = 1 # applied
				and undoneStatusID is null # status change has not been undone
				and contact.firstName <> 'Test'
				and contact.lastName <> 'Test'
				and contact.lastName <> 'testSD'
		inner join gtc
			on contact.contactID = gtc.contactID
				and contact.contactID is not null
				and contact.contactID > 0
	left join sptmp_maxSchoolDistrict tmpSD 
		on contact.contactId = tmpSD.contactId
	#pull in 2=enroll, 3-exited, 13=ytc cred, 14=ytc ell cred, 15=ytc ell attend, 16=ytc attend, 4=waitlisted, 5=application denied
	# only show apppliants that do not have one of these after application, i.e. are still in applicant status
	left join ( 
		select contactID
			, max(statusDate) as maxStatusDate
		from status 
		where status.keyStatusID IN (2, 3, 4, 5, 13, 14, 15, 16)
			and undoneStatusID is null # status change hasnt been undone
            and status.statusDate >= paramStartDate
			and status.statusDate <= paramEndDate
		group by status.contactID
		) maxStatus 
			on maxStatus.contactID = contact.contactID
	where status.statusDate >= paramStartDate
			and status.statusDate <= paramEndDate
            and fnGetProgramName(status.program) = 'GtC' #this applicant status only applies to this program
            #here is where we limit it those that are still in this status
			and (maxStatus.maxStatusDate is null 
				OR maxStatus.maxStatusDate < status.statusDate)	
			and (tmpSD.keySchoolDistrictId = paramSchoolDistrictID or paramSchoolDistrictID = 0)
	group by bannerGNumber
		, contact.contactID
		, firstName
		, lastName
		, emailPCC
		, emailAlt
		, fnGetProgramName(program) 
		, status.statusDate 
		, contact.hsCreditsEntry
		, contact.hsGpaEntry
		, interviewScore
		, evalEssayScore
		, evalGrammarScore
		, evalMathScore
		, evalReadingScore;
    
END$$
DELIMITER ;
