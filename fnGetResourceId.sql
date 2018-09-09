DELIMITER $$
CREATE DEFINER=`root`@`10.14.%` FUNCTION `fnGetResourceId`(paramContactID int, paramMaxStatusDate datetime) RETURNS int(11)
    DETERMINISTIC
BEGIN
    
    DECLARE id int;
    select keyResourceSpecialistID into id
	from (select contactID, substring_index(maxDateString, ':', -1) as statusID
			from ( SELECT contactID, max(concat(statusDate, ':', statusID)) as maxDateString
				   FROM status 
				   WHERE undoneStatusID IS NULL AND keyStatusID = 6 #resource assigned
						and statusDate < paramMaxStatusDate
						and contactID = paramContactId
				   GROUP BY contactID                        
				  ) maxResource
			) resource 
		inner join statusResourceSpecialist  
			on resource.statusID = statusResourceSpecialist.statusID;
            
	return id;
	END$$
DELIMITER ;
