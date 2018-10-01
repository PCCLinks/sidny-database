DELIMITER //
DROP PROCEDURE IF EXISTS spRebuildReportingStudentProgramYearYtCTables//
CREATE PROCEDURE spRebuildReportingStudentProgramYearYtCTables()
BEGIN

call spPopulateTmpEnrollExit(0);

DROP TABLE IF EXISTS sptmp_eeData;
CREATE TABLE sptmp_eeData
select py.ProgramYear
	,py.ProgramYearBeginDate
    ,py.ProgramYearEndDate
    ,py.ProgramYearTermBegin
    ,py.ProgramYearTermEnd
    ,max(ee.ID) maxID
    ,min(ee.ID) minID
    ,min(bc.Term) minTerm
    ,max(bc.Term) maxTerm
from sptmp_EnrollExit ee
join (select ProgramYear
			,min(termBeginDate) ProgramYearBeginDate
			,max(termEndDate) ProgramYearEndDate
            ,min(Term) ProgramYearTermBegin
            ,max(Term) ProgramYearTermEnd
		  from bannerCalendar
		  group by ProgramYear) py
		on ee.enrolledDate <= py.ProgramYearEndDate
			and (ee.exitDate >= py.ProgramYearBeginDate
					or ee.exitDate is null) 
join bannerCalendar bc
	on ee.enrolledDate <= bc.TermEndDate
		and (ee.exitDate >= bc.TermBeginDate or ee.exitDate is null)
        and py.ProgramYear = bc.ProgramYear
where ee.Program = 'YtC'
group by ee.contactID, ee.Program, py.ProgramYear, py.ProgramYearBeginDate, py.ProgramYearEndDate, ProgramYearTermBegin, ProgramYearTermEnd;

DROP TEMPORARY TABLE IF EXISTS sptmp_Exit;
CREATE TEMPORARY TABLE sptmp_Exit
select sptmp_eeData.maxID ID
	, ProgramYear
	, CASE WHEN sptmp_EnrollExit.exitDate IS NULL THEN NULL
		WHEN sptmp_EnrollExit.exitDate > sptmp_eeData.ProgramYearEndDate THEN NULL
        ELSE sptmp_EnrollExit.exitDate END exitDate
	, exitReason
    , secondaryReason
from sptmp_eeData
    join sptmp_EnrollExit on sptmp_eeData.maxID = sptmp_EnrollExit.ID;
    
CREATE INDEX idx_sptmp_Exit ON sptmp_Exit(ID);

#create temporary table since need to reconnect below
DROP TEMPORARY TABLE IF EXISTS sptmp_studentProgramYearYtC;
SET @row_number:=0;
CREATE TEMPORARY TABLE sptmp_studentProgramYearYtC
select @row_number:=@row_number+1 ID
	,eeEntry.contactId, eeEntry.bannerGNumber, eeEntry.SchoolDistrict, eeEntry.programDetail Program
    ,eeEntry.studentDistrictNumber
    ,eeData.ProgramYear
    ,eeExit.exitReason
    ,eeEntry.enrolledDate
    ,eeExit.exitDate
    ,eeExit.secondaryExitReason        
    ,eeExit.IsActiveStudent
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
			CASE WHEN IFNULL(YtcGEDMaxTestDate, YesGEDMaxTestDate) < eeData.ProgramYearBeginDate THEN 'PriorProgramYear'
				  WHEN IFNULL(YtcGEDMaxTestDate, YesGEDMaxTEstDate) BETWEEN eeData.ProgramYearBeginDate AND eeData.ProgramYearEndDate THEN 'DuringProgramYear'
				  ELSE 'None' END
          END GEDCompletedCode
    ,eeData.minTerm, eeData.maxTerm
    ,MAX(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' THEN substring(Title,7,1) ELSE NULL END)  MaxESOLLevel
    ,MIN(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' THEN substring(Title,7,1) ELSE NULL END)  MinESOLLevel
    ,MAX(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' AND Passed='Y' THEN substring(Title,7,1) ELSE NULL END)  MaxESOLLevelPassed
    ,(SELECT distinct 1
      FROM banner.swvlinks_course
      WHERE SUBJ = 'ESOL'
		and Term <= eeData.ProgramYearTermEnd
        and STU_ID = eeEntry.bannerGNumber) ESOLStudent
    ,(SELECT MAX(CASE WHEN SUBJ='ESOL' and LEFT(Title,5) = 'Level' THEN substring(Title,7,1) ELSE NULL END)  
      FROM banner.swvlinks_course
      WHERE SUBJ = 'ESOL'
		and Term < eeData.ProgramYearTermBegin
        and STU_ID = eeEntry.bannerGNumber) IncomingESOLLevel
    ,TIMESTAMPDIFF(YEAR, dob, eeEntry.enrolledDate) as AgeAtEntry
    ,c.hsCreditsEntry
    ,c.lastHSattended
    ,eeEntry.Coach
    ,c.firstName
    ,c.lastName
from sptmp_eeData eeData
    join (
		select ID, exitDate, ProgramYear
			,CASE WHEN exitDate IS NULL THEN NULL
				ELSE exitReason END exitReason
			,CASE WHEN exitDate IS NULL THEN NULL
				ELSE secondaryReason END secondaryExitReason        
			,CASE WHEN exitDate IS NULL THEN 1 
				ELSE 0 END IsActiveStudent
		  from sptmp_Exit
          ) eeExit  on eeData.maxID = eeExit.ID
			and eeData.ProgramYear = eeExit.ProgramYear
    join sptmp_EnrollExit eeEntry on eeData.minID = eeEntry.ID
    join contact c on eeEntry.contactID = c.contactID
	join bannerCalendar bc 
		on eeData.ProgramYear = bc.ProgramYear
	join banner.swvlinks_course crs
		on bc.term = crs.Term
			and eeEntry.bannerGNumber = crs.STU_ID
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
			and YtcGEDMaxTestDate <= ProgramYearEndDate
	left join (
			select contactId
				, GREATEST(yes.gedSocStudiesDate, yes.gedScienceDate, yes.gedMathDate, yes.gedLitDate, yes.gedWritingDate) YesGEDMaxTestDate
                , CASE when gedSocStudiesScore >= 410 and gedScienceScore >= 410 and gedMathScore >= 410 and gedLitScore >= 410 and gedWritingScore >= 410 
						then 'Passed'
						else NULL end as yesGedPassed
            from sidny.yes
		) yes on eeEntry.contactID = yes.contactID
			and YesGEDMaxTestDate <= ProgramYearEndDate
#where ee.bannerGNumber =  'G03763711'
group by contactId, bannerGNumber, ProgramYear, eeData.minTerm, eeData.maxTerm
	,SchoolDistrict, keySchoolDistrictID
    ,studentDistrictNumber, bc.ProgramYear, eeExit.exitReason 
    ,eeEntry.enrolledDate, eeExit.exitDate, eeExit.secondaryExitReason, eeExit.IsActiveStudent
	,gedMapSocStudiesScore, gedMapScienceScore, gedMapMathScore
    ,gedMapLitScore, gedMapWritingScore,gedMapLanguageArtsScore;

#created temporary table since need to reconnect below
DROP TABLE IF EXISTS reporting.studentProgramYearYtC;
CREATE TABLE reporting.studentProgramYearYtC
SELECT *
	,CAST(NULL AS DECIMAL(10,2)) AS PostGEDGPA
    ,CAST(NULL AS DECIMAL(10,2)) AS PostGEDTermCount
FROM sptmp_studentProgramYearYtC;

UPDATE reporting.studentProgramYearYtC
	JOIN ( SELECT ID 
		, SUM(CASE WHEN GRADE = 'A' THEN Credits * 4
				WHEN Grade = 'B' THEN Credits * 3
                WHEN Grade = 'C' THEN Credits * 2
                WHEN Grade  = 'D' THEN Credits * 1
                WHEN Grade = 'F' THEN Credits * 0
		END) GEDPoints
		,SUM(CASE WHEN Grade IN ('A','B','C','D','F') THEN Credits ELSE 0 END) Credits
        ,COUNT(distinct bc.Term) NumberOfTerms
	FROM sptmp_studentProgramYearYtC student
		join bannerCalendar bc 
			on (bc.TermBeginDate >= GEDMaxTestDate and GEDMaxTestDate is not null)
				and (bc.Term <= student.maxTerm OR student.maxTerm IS NULL)
		join banner.swvlinks_course crs
            on bc.term = crs.Term
				and student.bannerGNumber = crs.STU_ID
	GROUP  BY ID) data
		on reporting.studentProgramYearYtC.ID = data.ID
SET PostGEDGPA =  round(data.GEDPoints / data.credits,2)
	, PostGEDTermCount  = data.NumberOfTerms;
END//
DELIMITER ;