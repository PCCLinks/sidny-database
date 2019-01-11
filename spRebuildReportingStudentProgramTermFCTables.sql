DELIMITER //
DROP PROCEDURE IF EXISTS spRebuildReportingStudentProgramTermGtCTables//
CREATE PROCEDURE spRebuildReportingStudentProgramTermFCTables()
BEGIN

	DROP TABLE IF EXISTS reporting.studentProgramTermFC;
	CREATE TABLE reporting.studentProgramTermFC
	select fc.contactId
		,fc.bannerGNumber
		,fc.ExitReason
        ,fc.cohort
		,bc.ProgramYear
		,bc.Term
		,bc.TermBeginDate
		,bc.TermEndDate
		,CAST(NULL AS UNSIGNED) FirstTermEnrolled
		,CAST(NULL AS DATE) FirstTermEnrolledBeginDate
		,fc.Coach
        ,term.T_GPA termGPA
		,term.T_ATTEMPTED termCreditsAttempted
		,term.T_EARNED termCreditsEarned
	from futureConnect fc
		join contact c on fc.contactID = c.contactID
		join bannerCalendar bc 
			on bc.Term >= concat(fc.cohort,'04')
		join banner.swvlinks_course crs
			on bc.term = crs.Term
				and fc.bannerGNumber = crs.STU_ID
		join banner.swvlinks_term term
			on bc.term = term.term
				and fc.bannerGNumber = term.STU_ID
	group by fc.contactId
		,fc.bannerGNumber
        ,fc.ExitReason
		,bc.ProgramYear
		,bc.Term
		,bc.TermBeginDate
		,bc.TermEndDate
		,fc.Coach
        ,term.T_GPA 
		,term.T_ATTEMPTED 
		,term.T_EARNED;
				
	DROP TEMPORARY TABLE IF EXISTS sptmp_studentProgramTermFCMin;
	CREATE TEMPORARY TABLE sptmp_studentProgramTermFCMin
	select contactId
		,min(Term) minTerm
		,min(TermBeginDate) minTermBeginDate
	from reporting.studentProgramTermFC
	group by contactId;
				
	CREATE INDEX idx_sptmp_studentProgramTermFCMin ON sptmp_studentProgramTermFCMin(contactID);

	UPDATE reporting.studentProgramTermFC
		JOIN sptmp_studentProgramTermFCMin
			on reporting.studentProgramTermFC.contactId = sptmp_studentProgramTermFCMin.contactId
	SET FirstTermEnrolled =  sptmp_studentProgramTermFCMin.minTerm,
		FirstTermEnrolledBeginDate = sptmp_studentProgramTermFCMin.minTermBeginDate;


END//
DELIMITER ;
