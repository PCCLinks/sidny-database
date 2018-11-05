DELIMITER //
DROP PROCEDURE IF EXISTS spGetCurrentExitDate//
CREATE PROCEDURE spGetCurrentExitDate(IN paramContactID int, IN paramBannerGNumber varchar(25))
BEGIN
    
    IF (paramContactID = 0) THEN 
		SELECT contactID INTO paramContactID
		from contact
		where bannerGNumber = paramBannerGNumber;
    END IF;
    
	call spPopulateTmpEnrollExit(paramContactID);
    
    select firstname, lastname, contact.bannerGNumber, enrolledDate, exitDate, programDetail  
    from sptmp_CurrentEnrollExit ee
		join contact on ee.contactID = contact.contactID;

END//
DELIMITER ;
