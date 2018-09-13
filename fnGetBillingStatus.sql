DELIMITER //
DROP FUNCTION IF EXISTS fnGetBillingStatus;
//
CREATE FUNCTION fnGetBillingStatus(paramBillingStudentId INT(11)) RETURNS varchar(25)
BEGIN
	DECLARE paramIncludeFlag tinyint(4);
    DECLARE paramType varchar(10);
    DECLARE paramBillingStartDate date;
    DECLARE paramReviewed tinyint(4);
    DECLARE paramClosedDate date;
    DECLARE paramStatus varchar(25);
    DECLARE paramCnt INT(11);
    DECLARE paramPIDM INT(11);

	SELECT IncludeFlag
        ,CASE when Program like '%attendance%' then 'Attendance' ELSE 'Term' END
        ,billingStartDate
        ,BillingReviewedFlag
        ,PIDM
        INTO paramIncludeFlag, paramType, paramBillingStartDate, paramReviewed, paramPIDM
	FROM billingStudent 
   WHERE billingStudentId = paramBillingStudentId;

	SELECT billingCloseDate INTO paramClosedDate from billingCycle WHERE billingStartDate = paramBillingStartDate and billingType = paramType;
    
    IF paramPIDM IS NULL THEN
		set paramStatus = 'Missing Banner Attribute';
	ELSEIF paramIncludeFlag = 0 and paramClosedDate IS NOT NULL THEN
		set paramStatus = 'Excluded';
	ELSEIF paramIncludeFlag = 0 and paramClosedDate IS NULL THEN
		set paramStatus = 'Excluded from Billing';
	ELSEIF paramClosedDate IS NOT NULL THEN
		SET paramStatus = 'Billed';
	ELSE
		SELECT COUNT(*) INTO paramCnt FROM billingStudentItem WHERE billingStudentId = paramBillingStudentId;
        IF paramCnt = 0 THEN
			SET paramStatus = 'No Classes';
		ELSEIF paramReviewed = 1 THEN
			SET paramStatus = 'Reviewed';
		ELSE
			SET paramStatus = 'In Progress';
		END IF;
	END IF;
    
    RETURN paramStatus;
    
END//
DELIMITER ;
