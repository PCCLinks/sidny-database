DELIMITER $$
CREATE FUNCTION `fnGetSecondaryReason`(paramStatusId int) RETURNS varchar(1000) CHARSET latin1
    DETERMINISTIC
BEGIN
    
    DECLARE SecondaryReason varchar(1000);
		select GROUP_CONCAT(ksr2.reasonText ORDER BY ksr2.reasonText DESC) into SecondaryReason
		from statusReasonSecondary
			join keyStatusReason ksr2
					on ksr2.keyStatusReasonID = statusReasonSecondary.keyStatusReasonID 
		where statusReasonSecondary.statusID != 0
			and statusReasonSecondary.statusID = paramStatusId;
        
        RETURN secondaryReason;
    END$$
DELIMITER ;
