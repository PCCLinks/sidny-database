DELIMITER //
DROP PROCEDURE IF EXISTS spRebuildReportingStudentProgramTermGtCTables//
CREATE PROCEDURE spRebuildReportingStudentProgramTermGtCTables()
BEGIN

call spPopulateTmpEnrollExit(0);

DROP TEMPORARY TABLE IF EXISTS sptmp_eeData;
CREATE TEMPORARY TABLE sptmp_eeData
select py.ProgramYear
	,py.Term
	,py.TermBeginDate
    ,py.TermEndDate
    ,max(ee.ID) maxID
    ,min(ee.ID) minID
from sptmp_EnrollExit ee
join bannerCalendar bc
	on ee.enrolledDate <= bc.TermEndDate
		and (ee.exitDate >= bc.TermBeginDate or ee.exitDate is null)
where ee.Program = 'GtC' #and ee.contactId = (select contactId from contact where BannerGNumber = 'G03970412')
group by ee.contactID, ee.Program, bc.ProgramYear, bc.Term, bc.TermBeginDate, bc.TermEndDate, bc.NextTermBeginDate;

DROP TEMPORARY TABLE IF EXISTS sptmp_Exit;
CREATE TEMPORARY TABLE sptmp_Exit
select sptmp_eeData.maxID ID
    , ProgramYear
	, Term
	, CASE WHEN sptmp_EnrollExit.exitDate IS NULL THEN NULL
		WHEN sptmp_EnrollExit.exitDate > sptmp_eeData.NextTermBeginDate THEN NULL
        ELSE sptmp_EnrollExit.exitDate END exitDate
	, exitReason
    , secondaryReason
from sptmp_eeData
    join sptmp_EnrollExit on sptmp_eeData.maxID = sptmp_EnrollExit.ID;
    
CREATE INDEX idx_sptmp_Exit ON sptmp_Exit(ID);


DROP TABLE IF EXISTS reporting.studentProgramTermGtC;
SET @row_number:=0;
CREATE TABLE reporting.studentProgramTermGtC
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
    ,CAST(NULL AS UNSIGNED) IsNewStudent
    ,CAST(NULL AS UNSIGNED) FirstTermEnrolled
    ,CAST(NULL AS DATE) FirstTermEnrolledBeginDate
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
#where ee.bannerGNumber =  'G03763711'
group by contactId, bannerGNumber, ProgramYear, eeData.Term 
	,SchoolDistrict, keySchoolDistrictID
    ,studentDistrictNumber, bc.ProgramYear, eeExit.exitReason 
    ,eeEntry.enrolledDate, eeExit.exitDate, eeExit.secondaryExitReason, eeExit.IsActiveStudent;

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
    
UPDATE reporting.studentProgramTermGtC
	JOIN sptmp_minTerm
		on reporting.studentProgramTermGtC.contactId = sptmp_minTerm.contactId
SET IsNewStudent = (reporting.studentProgramTermGtC.Term = sptmp_minTerm.minTerm),
	FirstTermEnrolled =  sptmp_minTerm.minTerm,
    FirstTermEnrolledBeginDate = sptmp_minTerm.minTermBeginDate;


END//
DELIMITER ;
