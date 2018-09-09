DELIMITER $$
CREATE FUNCTION `fnGetGrade`(paramDOB date, banneryear int) RETURNS varchar(10) CHARSET latin1
BEGIN
	

	RETURN CASE
		WHEN paramDOB < date(concat(banneryear-21,'-09-01')) then 'Over'
		WHEN paramDOB < date(concat(banneryear-20,'-09-01')) then 12
		WHEN paramDOB < date(concat(banneryear-19,'-09-01')) then 12
		WHEN paramDOB < date(concat(banneryear-18,'-09-01')) then 12
		WHEN paramDOB < date(concat(banneryear-17,'-09-01')) then 12
		WHEN paramDOB < date(concat(banneryear-16,'-09-01')) then 11
		WHEN paramDOB < date(concat(banneryear-15,'-09-01')) then 10
		WHEN paramDOB < date(concat(banneryear-14,'-09-01')) then 9
	end;
END$$
DELIMITER ;
