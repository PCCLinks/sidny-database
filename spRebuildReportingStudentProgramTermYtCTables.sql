DELIMITER //
DROP PROCEDURE IF EXISTS spRebuildReportingStudentProgramTermYtCTables//
CREATE PROCEDURE spRebuildReportingStudentProgramTermYtCTables()
BEGIN

call spPopulateTmpEnrollExit(0);

DROP TEMPORARY TABLE IF EXISTS sptmp_eeData;
CREATE TEMPORARY TABLE sptmp_eeData
select bc.ProgramYear
	,bc.Term
	,bc.TermBeginDate
    ,bc.TermEndDate
    ,bc.NextTermBeginDate
    ,max(ee.ID) maxID
    ,min(ee.ID) minID
from sptmp_EnrollExit ee
join bannerCalendar bc
	on ee.enrolledDate <= bc.TermEndDate
		and (ee.exitDate >= bc.TermBeginDate or ee.exitDate is null)
where ee.Program = 'YtC' #and ee.contactId = (select contactId from contact where BannerGNumber = 'G03970412')
group by ee.contactID, ee.Program, bc.ProgramYear, bc.Term, bc.TermBeginDate, bc.TermEndDate, bc.NextTermBeginDate;

#build Exit data - pass #1
DROP TEMPORARY TABLE IF EXISTS sptmp_Exit1;
CREATE TEMPORARY TABLE sptmp_Exit1
select sptmp_eeData.maxID ID
    ,sptmp_eeData.ProgramYear
	,sptmp_eeData.Term
	,CASE WHEN sptmp_EnrollExit.exitDate IS NULL THEN NULL
 		WHEN sptmp_EnrollExit.exitDate > sptmp_eeData.NextTermBeginDate THEN NULL
        ELSE sptmp_EnrollExit.exitDate END termExitDate
	,exitDate
	,exitReason
    ,secondaryReason
    ,bc.TermEndDate
    ,(select max(t.Term) from banner.swvlinks_term t join bannerCalendar bc on t.Term = bc.Term where t.stu_id = sptmp_EnrollExit.bannerGNumber and (sptmp_EnrollExit.exitDate >= bc.TermBeginDate or sptmp_EnrollExit.exitDate is null)) maxTerm
from sptmp_eeData
    join sptmp_EnrollExit on sptmp_eeData.maxID = sptmp_EnrollExit.ID
    join bannerCalendar bc on sptmp_eeData.Term = bc.Term;

#exit data - final pass - handles where the exit date is outside of the last term attended
#in that case, sets the exit date to the ending date of the term
#doing this, because only want to show terms where the student attendend class
DROP TEMPORARY TABLE IF EXISTS sptmp_Exit;
CREATE TEMPORARY TABLE sptmp_Exit
SELECT ID
	,ProgramYear
    ,Term
    ,CASE WHEN Term = maxTerm AND termExitDate is NULL and exitDate IS NOT NULL THEN TermEndDate
		ELSE termExitDate END exitDate
	 ,exitReason
     ,secondaryReason
FROM sptmp_Exit1
WHERE Term <= maxTerm;
    
CREATE INDEX idx_sptmp_Exit ON sptmp_Exit(ID);

#create temporary table since need to reconnect below
DROP TEMPORARY TABLE IF EXISTS sptmp_studentProgramTermYtC;
SET @row_number:=0;
CREATE TEMPORARY TABLE sptmp_studentProgramTermYtC
select @row_number:=@row_number+1 ID
	,eeEntry.contactId, eeEntry.bannerGNumber, eeEntry.SchoolDistrict, eeEntry.programDetail Program
    ,eeEntry.studentDistrictNumber
    ,eeData.ProgramYear
    ,eeData.Term
    ,eeExit.exitReason
    ,eeEntry.enrolledDate
    ,eeExit.exitDate
    ,eeExit.secondaryExitReason        
    ,eeExit.IsActiveStudent
	,term.T_GPA termGPA
	,term.T_ATTEMPTED termCreditsAttempted
	,term.T_EARNED termCreditsEarned
	,gedMapSocStudiesScore
	,gedMapScienceScore
	,gedMapMathScore
	,gedMapLitScore
	,gedMapWritingScore
    ,gedMapLanguageArtsScore
	,CASE WHEN IFNULL(YtcGEDMaxTestDate, YesGEDMaxTestDate) < '2017-07-01' THEN IFNULL(YtcGEDMaxTestDate, YesGEDMaxTestDate)
        ELSE NULL
	 END GEDMaxTestDate
	, IFNULL(ytcGedPassed, yesGedPassed) GEDPassedCode
    ,CASE WHEN  IFNULL(ytcGedPassed, yesGedPassed) IS NULL THEN 'None'
		  WHEN IFNULL(ytcGedPassed, yesGedPassed) = 'Passed' THEN
			CASE WHEN IFNULL(YtcGEDMaxTestDate, YesGEDMaxTestDate) < eeData.TermBeginDate THEN 'PriorTerm'
				  WHEN IFNULL(YtcGEDMaxTestDate, YesGEDMaxTEstDate) BETWEEN eeData.TermBeginDate AND eeData.TermEndDate THEN 'DuringTerm'
				  ELSE 'None' END
          END GEDCompletedCode
    ,MAX(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' THEN substring(Title,7,1) ELSE NULL END)  MaxESOLLevel
    ,MIN(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' THEN substring(Title,7,1) ELSE NULL END)  MinESOLLevel
    ,MAX(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' AND Passed='Y' THEN substring(Title,7,1) ELSE NULL END)  MaxESOLLevelPassed
    ,(SELECT distinct 1
      FROM banner.swvlinks_course
      WHERE SUBJ = 'ESOL'
		and Term <= eeData.Term
        and STU_ID = eeEntry.bannerGNumber) ESOLStudent
    ,(SELECT MAX(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' THEN substring(Title,7,1) ELSE NULL END)  
      FROM banner.swvlinks_course
      WHERE SUBJ = 'ESOL'
		and Term < eeData.Term
        and STU_ID = eeEntry.bannerGNumber) IncomingESOLLevel
    ,TIMESTAMPDIFF(YEAR, dob, eeEntry.enrolledDate) as AgeAtEntry
    ,c.hsCreditsEntry
    ,c.lastHSattended
    ,eeEntry.Coach
    ,c.firstName
    ,c.lastName
from sptmp_eeData eeData
    join (
		select ID, exitDate, ProgramYear, Term
			,CASE WHEN exitDate IS NULL THEN NULL
				ELSE exitReason END exitReason
			,CASE WHEN exitDate IS NULL THEN NULL
				ELSE secondaryReason END secondaryExitReason        
			,CASE WHEN exitDate IS NULL THEN 1 
				ELSE 0 END IsActiveStudent
		  from sptmp_Exit
          ) eeExit  on eeData.maxID = eeExit.ID
			and eeData.Term = eeExit.Term
    join sptmp_EnrollExit eeEntry on eeData.minID = eeEntry.ID
    join contact c on eeEntry.contactID = c.contactID
	join bannerCalendar bc 
		on eeData.Term = bc.Term
	join banner.swvlinks_course crs
		on bc.term = crs.Term
			and eeEntry.bannerGNumber = crs.STU_ID
	join banner.swvlinks_term term
		on bc.term = term.term
			and eeEntry.bannerGNumber = term.STU_ID
	left join (
			select contactId
				,date_format(GREATEST(coalesce(gedMapSocStudiesDate,0), coalesce(gedMapScienceDate,0), coalesce(gedMapMathDate,0), coalesce(gedMapLitDate,0), coalesce(gedMapWritingDate,0), coalesce(gedMapLanguageArtsDate,0)), "%Y-%m-%d") YtcGEDMaxTestDate 
				,case when gedMapSocStudiesScore >= 410 
							and gedMapScienceScore >= 410 
                            and gedMapMathScore >= 410 
                            and gedMapLitScore >= 410 
                            and gedMapWritingScore >= 410
							and GREATEST(gedMapSocStudiesDate, gedMapScienceDate, gedMapMathDate, gedMapLitDate, gedMapWritingDate) < '2014-01-01' then 'Passed'
						when gedMapSocStudiesScore >= 145 
							and gedMapScienceScore >= 145 
                            and gedMapMathScore >= 145 
                            and gedMapLanguageArtsScore >= 145 
							and GREATEST(gedMapSocStudiesDate, gedMapScienceDate, gedMapMathDate, gedMapLanguageArtsDate) >= '2014-01-01' then 'Passed'
						else NULL
				end as ytcGedPassed
                ,gedMapSocStudiesScore
                ,gedMapScienceScore
                ,gedMapMathScore
                ,gedMapLitScore
                ,gedMapWritingScore
                ,gedMapLanguageArtsScore
            from sidny.ytc
  		) ytc on eeEntry.contactID = ytc.contactID
			and YtcGEDMaxTestDate <= eeData.TermEndDate
	left join (
			select contactId
				, GREATEST(yes.gedSocStudiesDate, yes.gedScienceDate, yes.gedMathDate, yes.gedLitDate, yes.gedWritingDate) YesGEDMaxTestDate
                , CASE when gedSocStudiesScore >= 410 and gedScienceScore >= 410 and gedMathScore >= 410 and gedLitScore >= 410 and gedWritingScore >= 410 
						then 'Passed'
						else NULL end as yesGedPassed
            from sidny.yes
		) yes on eeEntry.contactID = yes.contactID
			and YesGEDMaxTestDate <= eeData.TermEndDate
#where ee.bannerGNumber =  'G03763711'
group by contactId, bannerGNumber, ProgramYear, eeData.Term 
	,SchoolDistrict, keySchoolDistrictID
    ,studentDistrictNumber, bc.ProgramYear, eeExit.exitReason 
    ,eeEntry.enrolledDate, eeExit.exitDate, eeExit.secondaryExitReason, eeExit.IsActiveStudent
    ,term.T_GPA ,term.T_ATTEMPTED, term.T_EARNED
	,gedMapSocStudiesScore, gedMapScienceScore, gedMapMathScore
    ,gedMapLitScore, gedMapWritingScore,gedMapLanguageArtsScore;


#created temporary table since need to reconnect below
DROP TABLE IF EXISTS reporting.studentProgramTermYtC;
CREATE TABLE reporting.studentProgramTermYtC
SELECT *
	,CAST(NULL AS DECIMAL(10,2)) AS PostGEDGPA
    ,CAST(NULL AS DECIMAL(10,2)) AS PostGEDTermCount
    ,CAST(NULL AS SIGNED) AS IsNewStudent
    ,CAST(NULL AS UNSIGNED) FirstTermEnrolled
    ,CAST(NULL AS DATE) FirstTermEnrolledBeginDate
FROM sptmp_studentProgramTermYtC;

UPDATE reporting.studentProgramTermYtC
	JOIN ( SELECT ID 
		, SUM(CASE WHEN GRADE = 'A' THEN Credits * 4
				WHEN Grade = 'B' THEN Credits * 3
                WHEN Grade = 'C' THEN Credits * 2
                WHEN Grade  = 'D' THEN Credits * 1
                WHEN Grade = 'F' THEN Credits * 0
		END) GEDPoints
		,SUM(CASE WHEN Grade IN ('A','B','C','D','F') THEN Credits ELSE 0 END) Credits
        ,COUNT(distinct bc.Term) NumberOfTerms
	FROM sptmp_studentProgramTermYtC student
		join bannerCalendar bc 
			on (bc.TermBeginDate >= GEDMaxTestDate and GEDMaxTestDate is not null)
				and (bc.Term <= student.Term OR student.Term IS NULL)
		join banner.swvlinks_course crs
            on bc.term = crs.Term
				and student.bannerGNumber = crs.STU_ID
	GROUP  BY ID) data
		on reporting.studentProgramTermYtC.ID = data.ID
SET PostGEDGPA =  round(data.GEDPoints / data.credits,2)
	, PostGEDTermCount  = data.NumberOfTerms;


#populate if this is the student's first enroll at Links
DROP TEMPORARY TABLE IF EXISTS sptmp_minTerm;
CREATE TEMPORARY TABLE sptmp_minTerm
select contactId
	,min(py.Term) minTerm
    ,min(py.TermBeginDate) minTermBeginDate
from sptmp_EnrollExit ee
join (select ProgramYear 
			,Term
			,min(termBeginDate)TermBeginDate
			,max(termEndDate) TermEndDate
		  from bannerCalendar
		  group by ProgramYear, Term) py
		on ee.enrolledDate <= py.TermEndDate
			and (ee.exitDate >= py.TermBeginDate
					or ee.exitDate is null) 
join bannerCalendar bc
	on ee.enrolledDate <= bc.TermEndDate
		and (ee.exitDate >= bc.TermBeginDate or ee.exitDate is null)
        and py.Term = bc.Term
join (select distinct Term from banner.swvlinks_course) course
  on bc.term = course.term
group by ee.contactID;

CREATE INDEX idx_sptmp_minTerm ON sptmp_minTerm(contactID);
    
UPDATE reporting.studentProgramTermYtC
	JOIN sptmp_minTerm
		on reporting.studentProgramTermYtC.contactId = sptmp_minTerm.contactId
SET IsNewStudent = (reporting.studentProgramTermYtC.Term = sptmp_minTerm.minTerm),
	FirstTermEnrolled =  sptmp_minTerm.minTerm,
    FirstTermEnrolledBeginDate = sptmp_minTerm.minTermBeginDate;

    
END//
DELIMITER ;
