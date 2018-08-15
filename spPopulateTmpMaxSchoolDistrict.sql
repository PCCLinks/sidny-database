DELIMITER //
DROP PROCEDURE IF EXISTS spPopulateTmpMaxSchoolDistrict//
CREATE PROCEDURE spPopulateTmpMaxSchoolDistrict(IN paramEndDate datetime)
BEGIN
	/* Used by other procedures
	/  Gets the latest school district status entry that is < the passed in end date
    /  12/13/2017 Arlette Slachmuylder */
    
	DROP TEMPORARY TABLE IF EXISTS sptmp_maxSchoolDistrict;
    
	CREATE TEMPORARY TABLE sptmp_maxSchoolDistrict AS    
    SELECT status.contactId, status.statusDate, keySchoolDistrict.schoolDistrict, statusSchoolDistrict.keySchoolDistrictID
	 from status 
			  #parses the concatenated string to get the statusID
		JOIN (select substring_index(maxDateString, ':', -1) statusID
			#this creates a string of [status date] : [status id] allowing to get the 
            #combination of the max status date and associated id
			from ( select max(concat(statusDate, ':', statusID)) as maxDateString
					from status 
					where status.keyStatusID = (7) # SD status
						and undoneStatusID is null # status change hasnt been undone
						and statusDate < paramEndDate
					group by contactID
				) maxSchoolDistrict
		) schoolDistrict on status.statusID = schoolDistrict.statusID #TODO change alias
		join statusSchoolDistrict 
			on status.statusID = statusSchoolDistrict.statusID
		join keySchoolDistrict 
			on statusSchoolDistrict.keySchoolDistrictID = keySchoolDistrict.keySchoolDistrictID;
	
    CREATE INDEX idx_contact on sptmp_maxSchoolDistrict(contactId);
END//
DELIMITER ;
