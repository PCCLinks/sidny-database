DELIMITER //
DROP PROCEDURE IF EXISTS spRebuildReportingTables//
CREATE PROCEDURE spRebuildReportingTables()
BEGIN

	call spPopulateTmpEnrollExit(0);
    
    DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollExitCopy1;
    CREATE TEMPORARY TABLE sptmp_EnrollExitCopy1
    SELECT *
    FROM sptmp_EnrollExit;
    
    DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollExitCopy2;
    CREATE TEMPORARY TABLE sptmp_EnrollExitCopy2
    SELECT *
    FROM sptmp_EnrollExit;
    
    CREATE INDEX IDX_sptmp_EnrollExitCopy1 ON sptmp_EnrollExitCopy1(ID);
    CREATE INDEX IDX_sptmp_EnrollExitCopy2 ON sptmp_EnrollExitCopy2(ID);
    
    DROP TABLE IF EXISTS reporting.enrollExit;
    CREATE TABLE reporting.enrollExit
    SELECT data.*
        ,dataNext.Program transferredToProgram
        ,dataNext.ProgramDetail transferredToProgramDetail
        ,dataPrev.Program transferredFromProgram
        ,dataPrev.ProgramDetail transferredFromProgramDetail
        ,CASE WHEN data.exitDate IS NULL THEN 'Still Attending'
				WHEN data.exitReason = 'Graduated' THEN 'Graduated'
                WHEN dataNext.Program = 'YtC' AND reporting.fnGetGEDPassed(data.contactID) = 'Y' THEN 'Transferred to Yes & Earned GED'
                WHEN data.Program = dataNext.Program  THEN concat('Re-enrolled in ', data.Program)
                WHEN data.Program != dataNext.Program THEN concat('Transferred to ', dataNext.Program)
				WHEN data.exitReason like '%transfer%' THEN 'Transferred to another school'
				WHEN data.exitReason = 'Moved out of District/State (Specify District/State)' THEN 'Moved out of district'
				WHEN data.exitReason = '10 Days Absent' then '10 Days Absent'
                ELSE 'Exited Program' 
			END AS outcome
		,CASE WHEN data.exitDate IS NULL THEN 'Still Attending'
			WHEN data.exitReason = 'Graduated' THEN 'Graduated'
            ELSE 'Exited'
		  END basicOutcome
        ,CAST(NULL AS UNSIGNED) as termEnrolled
        ,CAST(NULL AS UNSIGNED) as termExit
        ,CAST('N' AS CHAR(1)) AS firstEnrollmentYN
        ,CAST('N' AS CHAR(1)) AS DroppedIn30DaysYN
        ,CAST(NULL AS UNSIGNED) as ageAtEntry
        ,CAST(NULL AS UNSIGNED) as ageAtExit
        ,CAST(NULL as CHAR(1)) as ESLClassTakenYN
        ,CAST(NULL as UNSIGNED) as ESOLLastTermTaken
        ,CAST(NULL as UNSIGNED) as postGED_GPACredits
        ,CAST(NULL as UNSIGNED) as postGED_GPAPoints
        ,CAST(NULL as UNSIGNED) as postNumberOfGEDTermsWithYtC
	FROM sptmp_EnrollExit data
		left outer join sptmp_EnrollExitCopy1 dataNext on data.contactId = dataNext.contactId
			and data.ID + 1 = dataNext.ID
		left outer join sptmp_EnrollExitCopy2 dataPrev on data.contactId = dataPrev.contactId
			and data.ID - 1 = dataPrev.ID;
            
	#add in some banner/term data    
    DROP TEMPORARY TABLE IF EXISTS sptmp_BannerData;
	CREATE TEMPORARY TABLE sptmp_BannerData AS 
    SELECT ID, min(swvlinks_course.term) minTerm, max(swvlinks_course.term) maxTerm
			,max(case when Subj = 'ESL' OR Subj = 'ESOL' then 'Y' else 'N' end) as ESLClassTakenYN
            ,MAX(CASE WHEN SUBJ = 'ESOL' and LEVL = 'CR' THEN swvlinks_course.TERM ELSE NULL END) ESOLLastTermTaken
	FROM sptmp_EnrollExit
		JOIN sidny.bannerCalendar on (enrolledDate < DATE_ADD(termBeginDate, INTERVAL 15 DAY) and exitDate > termBeginDate)
			OR (enrolledDate < DATE_ADD(termBeginDate, INTERVAL 15 DAY) and exitDate is null)
		JOIN banner.swvlinks_course on sptmp_EnrollExit.bannerGNumber = swvlinks_course.stu_id
			and bannerCalendar.term = swvlinks_course.term
	GROUP BY ID;
    
        
    CREATE INDEX idx_sptmp_BannerData ON sptmp_BannerData(ID);
    CREATE INDEX idx_enrollExit_ID ON reporting.enrollExit(ID);
    CREATE INDEX idx_enrollExit_contactID ON reporting.enrollExit(contactID);

	UPDATE reporting.enrollExit
		JOIN sptmp_BannerData on enrollExit.ID = sptmp_BannerData.ID
	SET enrollExit.termEnrolled = sptmp_BannerData.minTerm,
		enrollExit.termExit = sptmp_BannerData.maxTerm,
        enrollExit.ESLClassTakenYN = sptmp_BannerData.ESLClassTakenYN,
        enrollExit.ESOLLastTermTaken = sptmp_BannerData.ESOLLastTermTaken;
        
	UPDATE reporting.enrollExit
		JOIN (SELECT contactID, MIN(ID) ID FROM sptmp_EnrollExitCopy1 GROUP BY contactID) firstEnroll ON enrollExit.ID = firstEnroll.ID
	SET enrollExit.firstEnrollmentYN = 'Y'
		,enrollExit.droppedIn30DaysYN = IF(datediff(enrollExit.ExitDate, enrollExit.EnrolledDate) < 31 OR enrollExit.exitReason = 'Accepted/No Show', 'Y','N');
    
    UPDATE reporting.enrollExit
		JOIN contact on enrollExit.contactID = contact.contactID
	SET ageAtEntry = TIMESTAMPDIFF(YEAR, dob, enrolledDate)
		,ageAtExit = TIMESTAMPDIFF(YEAR, dob, exitDate);
   
   #add to currentEnrollExit
   
    DROP TEMPORARY TABLE IF EXISTS sptmp_CurrentEnrollExit1;
    
    CREATE TEMPORARY TABLE sptmp_CurrentEnrollExit1
    SELECT contactId, max(ID) ID, min(enrolledDate) minEnrolledDate, max(exitDate) maxExitDate
		,min(termEnrolled) minTermEnrolled
        ,max(termExit) maxTermEnrolled
        ,count(*) numberOfEnrollments
        ,sum(CASE WHEN Program = 'YtC' THEN 1 ELSE 0 END) numberOfYtCEnrollments
        ,sum(CASE WHEN Program = 'GtC' THEN 1 ELSE 0 END) numberOfGtCEnrollments
    FROM reporting.enrollExit
    GROUP BY contactId;

	CREATE INDEX idx_sptmp_CurrentEnrollExit1 on sptmp_CurrentEnrollExit1(id);

   #get latest exit entries per contactid
    DROP TEMPORARY TABLE IF EXISTS sptmp_CurrentEnrollExitRevised;
	CREATE TEMPORARY TABLE sptmp_CurrentEnrollExitRevised AS        
    SELECT ee.*
        ,minEnrolledDate
        ,maxExitDate
        ,minTermEnrolled
        ,maxTermEnrolled
        ,numberOfEnrollments
        ,numberOfYtCEnrollments
        ,numberOfGtCEnrollments
        ,CAST(NULL AS DATE) minYtCEnrolledDate, CAST(NULL AS DATE) maxYtcExitDate
        ,CAST(NULL AS DATE) minGtCEnrolledDate, CAST(NULL AS DATE) maxGtCExitDate
    FROM sptmp_CurrentEnrollExit ee
		join sptmp_CurrentEnrollExit1 latest
			on ee.ID = latest.ID;
            
	UPDATE sptmp_CurrentEnrollExitRevised
    JOIN (SELECT contactId, min(enrolledDate) minEnrolledDate, max(exitDate) maxExitDate
			FROM sptmp_EnrollExit 
			WHERE Program = 'YtC'
			GROUP BY contactId) data on sptmp_CurrentEnrollExitRevised.contactId = data.contactID
	SET minYtCEnrolledDate = data.minEnrolledDate,
		maxYtCExitDate = data.maxExitDate;
        
	UPDATE sptmp_CurrentEnrollExitRevised
    JOIN (SELECT contactId, max(ID) ID, min(enrolledDate) minEnrolledDate, max(exitDate) maxExitDate
			FROM sptmp_EnrollExit 
			WHERE Program = 'GtC'
			GROUP BY contactId) data on sptmp_CurrentEnrollExitRevised.contactId = data.contactID
	SET minGtCEnrolledDate = data.minEnrolledDate,
		maxGtCExitDate = data.maxExitDate;
    
    drop table IF EXISTS reporting.currentEnrollExit;
    create table reporting.currentEnrollExit
    select *
    from sptmp_CurrentEnrollExitRevised;
    
    CREATE INDEX idx_currentEnrollExit_contactID on reporting.currentEnrollExit(contactID);

	#build contact profile
	DROP TABLE IF EXISTS reporting.contactProfile;
    CREATE TABLE reporting.contactProfile
    SELECT contact.contactId
		,contact.bannerGNumber
        ,contact.lastname
        ,contact.firstname
        ,contact.middlename
        ,contact.dob
        ,contact.gender
        ,contact.hsCreditsEntry
        ,contact.hsGpaEntry
		,reporting.fnGetGEDPassed(contact.contactID) as GEDPassedYN
        ,reporting.fnGetGEDMaxDate(contact.contactID) as GEDMaxDate
        ,IFNULL(gedMapCompletionDate, gedCompletionDate) as GEDCompletionDate
        ,IFNULL(ytc.gedMapSocStudiesScore, yes.gedSocStudiesScore) GEDSocStudiesScore
        ,IFNULL(ytc.gedMapScienceScore, yes.gedScienceScore) GEDScienceScore
        ,IFNULL(ytc.gedMapMathScore, yes.gedMathScore) GEDMathScore
        ,IFNULL(ytc.gedMapWritingScore, yes.gedWritingScore) GEDWritingScore
        ,reporting.fnGetGEDLanguageArts(contact.contactID) as gedLanguageArtsScore
		,gtc.evalReadingScore as GtCEvalReadingScore
		,gtc.evalEssayScore as GtCEvalEssayScore
		,gtc.evalGrammarScore as GtCEvalGrammarScore
		,gtc.evalMathScore as GtCEvalMathScoree
		,gtc.interviewScore as GtCInterviewScore
        ,swvlinks_person.O_GPA
        ,swvlinks_person.O_Attempted
        ,swvlinks_person.O_EARNED
        ,swvlinks_person.REP_RACE
        ,CAST(NULL as unsigned) as GEDTermPassed
        ,esol.ESOL_Completion
    from sidny.contact
        LEFT JOIN sidny.gtc on contact.contactID = gtc.contactID
        LEFT JOIN (SELECT distinct STU_ID, O_GPA, O_Attempted, O_EARNED, REP_RACE
					 FROM banner.swvlinks_person) swvlinks_person  on contact.bannerGNumber = swvlinks_person.stu_id
		LEFT JOIN (SELECT STU_ID, MAX(CASE WHEN TITLE IN ('Level 8 Academic Reading', 'Level 8 Academic Writing') and PASSED = 'Y' THEN 'Y' ELSE 'N' END) ESOL_Completion
					 FROM banner.swvlinks_course 
					GROUP BY STU_ID) esol on contact.bannerGNumber = esol.stu_id	 
		LEFT JOIN sidny.ytc on contact.contactID = ytc.contactID
        LEFT JOIN sidny.yes on contact.contactID = yes.contactID;
	
	UPDATE reporting.contactProfile
      left join sidny.bannerCalendar
		on GEDMaxDate >= bannerCalendar.TermBeginDate
			and GEDMaxDate < bannerCalendar.NextTermBeginDate
	SET gedTermPassed  =  bannerCalendar.Term;
                     
	CREATE INDEX IDX_contactProfile_contactID ON reporting.contactProfile(contactID);
    
    UPDATE reporting.enrollExit
		join (SELECT ID
				,SUM(CASE WHEN  GEDTermPassed < Term 
							and Term <= termExit
							and Grade IN ('A', 'B', 'C', 'D', 'F')
					THEN Credits END) postGED_GPACredits
				,SUM(CASE WHEN  GEDTermPassed < Term  and Term <= termExit 
						THEN Credits * (CASE Grade WHEN 'A' THEN 4 WHEN 'B' THEN 3 WHEN 'C' THEN 2 WHEN 'D' THEN 1 WHEN 'F' THEN 0 END)
					END) postGED_GPAPoints
				,COUNT(CASE WHEN term = GEDTermPassed
						and (ISNULL(TermExit) or Term <= TermExit)
					THEN Term end) postNumberOfGEDTermsWithYtC
				FROM reporting.enrollExit
					join reporting.contactProfile on enrollExit.contactId = contactProfile.contactID
                    join banner.swvlinks_course on contactProfile.bannerGNumber = swvlinks_course.stu_id 
			GROUP BY ID) data
            on enrollExit.ID = data.ID
	SET enrollExit.postGED_GPACredits = data.postGED_GPACredits
    ,enrollExit.postGED_GPAPoints = data.postGED_GPAPoints
    ,enrollExit.postNumberOfGEDTermsWithYtC = data.postNumberOfGEDTermsWithYtC;
    
END//
DELIMITER ;
