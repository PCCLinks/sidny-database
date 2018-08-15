DELIMITER //
DROP PROCEDURE IF EXISTS getStudentsToBill
//
CREATE PROCEDURE getStudentsToBill(IN paramBeginDate datetime, IN paramEndDate datetime, IN paramBannerGNumber varchar(50))
BEGIN

	DECLARE paramContactId INT default 0;
    IF length(paramBannerGNumber)>0
    THEN
		SELECT ContactID INTO paramContactID
        FROM contact 
        WHERE bannerGNumber = paramBannerGNumber;
	END IF;

	call spPopulateTmpEnrollExit(paramContactId);

	SELECT ee.contactId
		,ee.programDetail program
		,ee.enrolledDate 
		,c.lastName
		,c.firstName
        ,c.bannerGNumber
		,ee.exitDate
		,ee.schoolDistrict
		,ee.keySchoolDistrictID DistrictID
		,bs.PIDM
	FROM sptmp_EnrollExit ee
		JOIN contact c on ee.contactId = c.contactId
		LEFT OUTER JOIN (select distinct contactId, PIDM from billingStudent) bs ON c.contactID = bs.contactID
	WHERE (
			(ee.exitDate is null or ee.exitDate >= paramBeginDate) and ee.enrolledDate < paramEndDate
			)
		AND (c.bannerGNumber = paramBannerGNumber OR length(paramBannerGNumber)=0);

END//
DELIMITER ;
