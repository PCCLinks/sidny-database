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
CREATE TABLE reporting.enrollExit SELECT data.*,
    dataNext.Program transferredToProgram,
    dataNext.ProgramDetail transferredToProgramDetail,
    dataPrev.Program transferredFromProgram,
    dataPrev.ProgramDetail transferredFromProgramDetail,
    CASE
        WHEN data.exitDate IS NULL THEN 'Still Attending'
        WHEN data.exitReason = 'Graduated' THEN 'Graduated'
        WHEN
            dataNext.Program = 'YtC'
                AND reporting.fnGetGEDPassed(data.contactID) = 'Y'
        THEN
            'Transferred to Yes & Earned GED'
        WHEN data.Program = dataNext.Program THEN CONCAT('Re-enrolled in ', data.Program)
        WHEN data.Program != dataNext.Program THEN CONCAT('Transferred to ', dataNext.Program)
        WHEN data.exitReason LIKE '%transfer%' THEN 'Transferred to another school'
        WHEN data.exitReason = 'Moved out of District/State (Specify District/State)' THEN 'Moved out of district'
        WHEN data.exitReason = '10 Days Absent' THEN '10 Days Absent'
        ELSE 'Exited Program'
    END AS outcome,
    CASE
        WHEN data.exitDate IS NULL THEN 'Still Attending'
        WHEN data.exitReason = 'Graduated' THEN 'Graduated'
        ELSE 'Exited'
    END basicOutcome,
    CAST(NULL AS UNSIGNED) AS termEnrolled,
    CAST(NULL AS UNSIGNED) AS termExit,
    CAST('N' AS CHAR (1)) AS firstEnrollmentYN,
    CAST('N' AS CHAR (1)) AS DroppedIn30DaysYN,
    CAST(NULL AS UNSIGNED) AS ageAtEntry,
    CAST(NULL AS UNSIGNED) AS ageAtExit,
    CAST(NULL AS CHAR (1)) AS ESLClassTakenYN,
    CAST(NULL AS UNSIGNED) AS ESOLLastTermTaken,
    CAST(NULL AS UNSIGNED) AS postGED_GPACredits,
    CAST(NULL AS UNSIGNED) AS postGED_GPAPoints,
    CAST(NULL AS UNSIGNED) AS postNumberOfGEDTermsWithYtC FROM
    sptmp_EnrollExit data
        LEFT OUTER JOIN
    sptmp_EnrollExitCopy1 dataNext ON data.contactId = dataNext.contactId
        AND data.ID + 1 = dataNext.ID
        LEFT OUTER JOIN
    sptmp_EnrollExitCopy2 dataPrev ON data.contactId = dataPrev.contactId
        AND data.ID - 1 = dataPrev.ID;
            
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
        JOIN
    sptmp_BannerData ON enrollExit.ID = sptmp_BannerData.ID 
SET 
    enrollExit.termEnrolled = sptmp_BannerData.minTerm,
    enrollExit.termExit = sptmp_BannerData.maxTerm,
    enrollExit.ESLClassTakenYN = sptmp_BannerData.ESLClassTakenYN,
    enrollExit.ESOLLastTermTaken = sptmp_BannerData.ESOLLastTermTaken;
        
	UPDATE reporting.enrollExit
        JOIN
    (SELECT 
        contactID, MIN(ID) ID
    FROM
        sptmp_EnrollExitCopy1
    GROUP BY contactID) firstEnroll ON enrollExit.ID = firstEnroll.ID 
SET 
    enrollExit.firstEnrollmentYN = 'Y',
    enrollExit.droppedIn30DaysYN = IF(DATEDIFF(enrollExit.ExitDate,
                enrollExit.EnrolledDate) < 31
            OR enrollExit.exitReason = 'Accepted/No Show',
        'Y',
        'N');
    
UPDATE reporting.enrollExit
        JOIN
    contact ON enrollExit.contactID = contact.contactID 
SET 
    ageAtEntry = TIMESTAMPDIFF(YEAR, dob, enrolledDate),
    ageAtExit = TIMESTAMPDIFF(YEAR, dob, exitDate);
   
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
        JOIN
    (SELECT 
        contactId,
            MIN(enrolledDate) minEnrolledDate,
            MAX(exitDate) maxExitDate
    FROM
        sptmp_EnrollExit
    WHERE
        Program = 'YtC'
    GROUP BY contactId) data ON sptmp_CurrentEnrollExitRevised.contactId = data.contactID 
SET 
    minYtCEnrolledDate = data.minEnrolledDate,
    maxYtCExitDate = data.maxExitDate;
        
	UPDATE sptmp_CurrentEnrollExitRevised
        JOIN
    (SELECT 
        contactId,
            MAX(ID) ID,
            MIN(enrolledDate) minEnrolledDate,
            MAX(exitDate) maxExitDate
    FROM
        sptmp_EnrollExit
    WHERE
        Program = 'GtC'
    GROUP BY contactId) data ON sptmp_CurrentEnrollExitRevised.contactId = data.contactID 
SET 
    minGtCEnrolledDate = data.minEnrolledDate,
    maxGtCExitDate = data.maxExitDate;
    
    drop table IF EXISTS reporting.currentEnrollExit;
CREATE TABLE reporting.currentEnrollExit SELECT * FROM
    sptmp_CurrentEnrollExitRevised;
    
    CREATE INDEX idx_currentEnrollExit_contactID on reporting.currentEnrollExit(contactID);

	#build contact profile
	DROP TABLE IF EXISTS reporting.contactProfile;
CREATE TABLE reporting.contactProfile SELECT contact.contactId,
    contact.bannerGNumber,
    contact.lastname,
    contact.firstname,
    contact.middlename,
    contact.dob,
    contact.gender,
    contact.hsCreditsEntry,
    contact.hsGpaEntry,
    contact.lastHSattended,
    reporting.fnGetGEDPassed(contact.contactID) AS GEDPassedYN,
    reporting.fnGetGEDMaxDate(contact.contactID) AS GEDMaxDate,
    IFNULL(gedMapCompletionDate, gedCompletionDate) AS GEDCompletionDate,
    IFNULL(ytc.gedMapSocStudiesScore,
            yes.gedSocStudiesScore) GEDSocStudiesScore,
    IFNULL(ytc.gedMapScienceScore,
            yes.gedScienceScore) GEDScienceScore,
    IFNULL(ytc.gedMapMathScore, yes.gedMathScore) GEDMathScore,
    IFNULL(ytc.gedMapWritingScore,
            yes.gedWritingScore) GEDWritingScore,
    reporting.fnGetGEDLanguageArts(contact.contactID) AS gedLanguageArtsScore,
    gtc.evalReadingScore AS GtCEvalReadingScore,
    gtc.evalEssayScore AS GtCEvalEssayScore,
    gtc.evalGrammarScore AS GtCEvalGrammarScore,
    gtc.evalMathScore AS GtCEvalMathScoree,
    gtc.interviewScore AS GtCInterviewScore,
    swvlinks_person.O_GPA,
    swvlinks_person.O_Attempted,
    swvlinks_person.O_EARNED,
    swvlinks_person.REP_RACE,
    CAST(NULL AS UNSIGNED) AS GEDTermPassed,
    esol.ESOL_Completion FROM
    sidny.contact
        LEFT JOIN
    sidny.gtc ON contact.contactID = gtc.contactID
        LEFT JOIN
    (SELECT DISTINCT
        STU_ID, O_GPA, O_Attempted, O_EARNED, REP_RACE
    FROM
        banner.swvlinks_person) swvlinks_person ON contact.bannerGNumber = swvlinks_person.stu_id
        LEFT JOIN
    (SELECT 
        STU_ID,
            MAX(CASE
                WHEN
                    TITLE IN ('Level 8 Academic Reading' , 'Level 8 Academic Writing')
                        AND PASSED = 'Y'
                THEN
                    'Y'
                ELSE 'N'
            END) ESOL_Completion
    FROM
        banner.swvlinks_course
    GROUP BY STU_ID) esol ON contact.bannerGNumber = esol.stu_id
        LEFT JOIN
    sidny.ytc ON contact.contactID = ytc.contactID
        LEFT JOIN
    sidny.yes ON contact.contactID = yes.contactID;
	
	UPDATE reporting.contactProfile
        LEFT JOIN
    sidny.bannerCalendar ON GEDMaxDate >= bannerCalendar.TermBeginDate
        AND GEDMaxDate < bannerCalendar.NextTermBeginDate 
SET 
    gedTermPassed = bannerCalendar.Term;
                     
	CREATE INDEX IDX_contactProfile_contactID ON reporting.contactProfile(contactID);
    
UPDATE reporting.enrollExit
        JOIN
    (SELECT 
        ID,
            SUM(CASE
                WHEN
                    GEDTermPassed < Term
                        AND Term <= termExit
                        AND Grade IN ('A' , 'B', 'C', 'D', 'F')
                THEN
                    Credits
            END) postGED_GPACredits,
            SUM(CASE
                WHEN
                    GEDTermPassed < Term
                        AND Term <= termExit
                THEN
                    Credits * (CASE Grade
                        WHEN 'A' THEN 4
                        WHEN 'B' THEN 3
                        WHEN 'C' THEN 2
                        WHEN 'D' THEN 1
                        WHEN 'F' THEN 0
                    END)
            END) postGED_GPAPoints,
            COUNT(CASE
                WHEN
                    term = GEDTermPassed
                        AND (ISNULL(TermExit) OR Term <= TermExit)
                THEN
                    Term
            END) postNumberOfGEDTermsWithYtC
    FROM
        reporting.enrollExit
    JOIN reporting.contactProfile ON enrollExit.contactId = contactProfile.contactID
    JOIN banner.swvlinks_course ON contactProfile.bannerGNumber = swvlinks_course.stu_id
    GROUP BY ID) data ON enrollExit.ID = data.ID 
SET 
    enrollExit.postGED_GPACredits = data.postGED_GPACredits,
    enrollExit.postGED_GPAPoints = data.postGED_GPAPoints,
    enrollExit.postNumberOfGEDTermsWithYtC = data.postNumberOfGEDTermsWithYtC;
    
END//
DELIMITER ;
