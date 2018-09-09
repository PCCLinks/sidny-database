DELIMITER //
DROP PROCEDURE IF EXISTS spPopulateTmpEnrollExit//
CREATE PROCEDURE spPopulateTmpEnrollExit(IN paramContactID INT)
BEGIN
	#build out exit data to use later
	DROP TEMPORARY TABLE IF EXISTS sptmp_Exit;
	CREATE TEMPORARY TABLE sptmp_Exit AS
	select status.contactId
		, statusId
		, statusDate
	from status 
	where status.keyStatusID IN (12, 3)
		and undoneStatusID is null # status change hasnt been undoneundone
			and fnGetProgramName(program) in ('YtC', 'GtC')
		and (contactID = paramContactID or paramContactID = 0);

	#get all enrollment entries per contactid
	DROP TEMPORARY TABLE IF EXISTS sptmp_Enroll;
	CREATE TEMPORARY TABLE sptmp_Enroll AS
	select contactId 
		,fnGetProgramName(program) Program
		,statusDate
	from status
	# 2=enroll
	where status.keyStatusID IN (2) #enroll
		and undoneStatusID is null # status change hasnt been undone
        and fnGetProgramName(program) in ('YtC', 'GtC')
		and contactId not in (select contactID from contact where contact.firstName = 'Test'
				or contact.lastName = 'Test'
				or contact.lastName = 'testSD')
		and contactId != 0
		and (contactID = paramContactID or paramContactID = 0);
        
    CREATE INDEX idx_sptmp_Enroll ON sptmp_Enroll(contactId, statusDate);
    CREATE INDEX idx_sptmp_Exit ON sptmp_Exit(contactId, statusDate);
    
    #line it up with the exits, to consolidate it to a single row with entry and exit dates    
	DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollMinExit1;
	CREATE TEMPORARY TABLE sptmp_EnrollMinExit1 AS
	SELECT contactId
		,Program
		,statusDate
        ,Date(substring_index(minExitDateString,'|',1)) ExitDate
        ,substring_index(minExitDateString,'|',-1) ExitStatusId
	FROM(
	SELECT tmpEnroll.contactID
        ,tmpEnroll.Program
        ,tmpEnroll.statusDate
        ,min(concat(exitStatus.StatusDate, '|', exitStatus.statusId)) minExitDateString
    FROM sptmp_Enroll tmpEnroll
	LEFT JOIN sptmp_Exit exitStatus on tmpEnroll.contactId = exitStatus.contactId
		AND (exitStatus.statusDate >= tmpEnroll.statusDate
			or exitStatus.statusDate IS NULL)
	GROUP BY tmpEnroll.contactID
        ,tmpEnroll.Program
        ,tmpEnroll.statusDate) data;

	#now doing a second pass to get ytc enrolls - these sometimes match up with regular enrolls and sometimes not
    #also do not always have exits, just move from one program to another, but need to show that as an exit date
    #so going to determine "next row" as well
    DROP TEMPORARY TABLE IF EXISTS sptmp_ytcEnroll;    
	SET @row_number:=0;
	CREATE TEMPORARY TABLE sptmp_ytcEnroll AS
	select @row_number:=@row_number+1 ID
		,contactId 
		,keyStatusID
		,statusDate
        ,program
	from status
	where status.keyStatusID IN (13,14,15,16) #ytc enroll
		and undoneStatusID is null # status change hasnt been undone
		and contactId not in (select contactID from contact where contact.firstName = 'Test'
				or contact.lastName = 'Test'
				or contact.lastName = 'testSD')
		and contactId != 0
		and (contactID = paramContactID or paramContactID = 0)
    order by contactId, statusDate, statusID;
    
    #cannot join temp table back to itself with mysql
    #so creating duplicate
	DROP TEMPORARY TABLE IF EXISTS sptmp_ytcEnrollNext;
	CREATE TEMPORARY TABLE sptmp_ytcEnrollNext AS
    SELECT *
    FROM sptmp_ytcEnroll;
   
	#pass to join it to "next" to fabricate exit date if none is supplied
	DROP TEMPORARY TABLE IF EXISTS sptmp_YtcEnrollMinExit1;
	CREATE TEMPORARY TABLE sptmp_YtcEnrollMinExit1 AS
    SELECT tmpEnroll.contactID
        ,tmpEnroll.keyStatusID
        ,tmpEnroll.statusDate
        ,tmpEnroll.Program
        ,tmpEnrollNext.statusDate NextEnrollDate
    FROM sptmp_ytcEnroll tmpEnroll
    LEFT JOIN sptmp_ytcEnrollNext tmpEnrollNext on tmpEnroll.contactId = tmpEnrollNext.contactId
		and tmpEnroll.id+1 = tmpEnrollNext.id and tmpEnroll.keyStatusID != tmpEnrollNext.keyStatusID;

	#second pass to match with actual exit dates recorded
	DROP TEMPORARY TABLE IF EXISTS sptmp_YtcEnrollMinExit2;
	CREATE TEMPORARY TABLE sptmp_YtcEnrollMinExit2 AS
    SELECT contactID
		,keyStatusID
		,Program
        ,statusDate
        ,DATE(substring_index(YtCExitDateString,'|',1)) YtCExitDate
        ,substring_index(YtCExitDateString,'|',-1) YtCExitStatusID
        ,ExitDate
	FROM (
	SELECT tmpEnroll.contactID
        ,tmpEnroll.keyStatusID
        ,tmpEnroll.Program
        ,tmpEnroll.statusDate
        #consolidating - taking the earliest NextDate or ExitDate per the above fields
        ,min(CASE WHEN exitStatus.StatusDate IS NULL THEN concat(tmpEnroll.NextEnrollDate, '|', 0)
				WHEN tmpEnroll.NextEnrollDate < exitStatus.StatusDate THEN concat(tmpEnroll.NextEnrollDate,'|',0)
                ELSE concat(exitStatus.StatusDate,'|',exitStatus.statusID) END) YtCExitDateString
		,exitStatus.StatusDate ExitDate
    FROM sptmp_YtcEnrollMinExit1 tmpEnroll
	LEFT JOIN sptmp_Exit exitStatus on tmpEnroll.contactId = exitStatus.contactId
		#and tmpEnroll.Program = fnGetProgramName(exitStatus.program)
		AND (exitStatus.statusDate >= tmpEnroll.statusDate
			or exitStatus.statusDate IS NULL)
	GROUP BY tmpEnroll.contactID
        ,tmpEnroll.keyStatusID
        ,tmpEnroll.Program
        ,tmpEnroll.statusDate) data;

	#now going to build final set of data
    #first pass pulls in by contact and exit date to match general enrollments initially captured with ytc enrollments, and capture
    #actual YtC program, if available
    DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollExit1;
	CREATE TEMPORARY TABLE sptmp_EnrollExit1 AS
	SELECT data.contactId
		,IFNULL(keyStatus.statusText, data.Program) ProgramDetail
        ,data.Program
        ,CASE WHEN ytc.statusDate IS NULL THEN data.statusDate
			WHEN ytc.statusDate < data.statusDate THEN ytc.statusDate
            ELSE data.statusDate END enrolledDate
		,IFNULL(ytc.YtCExitDate, data.ExitDate) ExitDate
        ,IFNULL(ytc.YtCExitStatusID, data.ExitStatusID) ExitStatusID
	FROM sptmp_EnrollMinExit1 data
		left outer join sptmp_YtcEnrollMinExit2 ytc on data.contactid = ytc.contactid
			and (data.exitDate = ytc.exitDate or (data.exitDate is null and ytc.exitDate is null and data.Program = 'YtC'))
		left outer join keyStatus on ytc.keyStatusID = keyStatus.keyStatusID;
        
	#second pass pulls in where the ytc enrollment does not have a general type matching enrollment match
    #so not showing up in above set of data
	INSERT INTO sptmp_EnrollExit1
	SELECT ytc.contactId, keyStatus.statusText ProgramDetail
		,ytc.Program
        ,ytc.StatusDate EnrolledDate
        ,ytc.ExitDate ExitDate
        ,ytc.YtCExitStatusId
	FROM sptmp_YtcEnrollMinExit2 ytc
		inner join keyStatus on ytc.keyStatusID = keyStatus.keyStatusID
		left outer join sptmp_EnrollMinExit1 data on ytc.contactid = data.contactid
			and (ytc.exitDate = data.exitDate or (ytc.exitDate is null and data.exitDate is null and data.Program = 'YtC'))
	WHERE data.contactId is null;

    #one final pass to populate any missing exit dates
    #by figuring out "next" row
    #also tag if this is a "final" exit or just a program transition
    #and remove any duplicates and clean up 0 ids to null
    
    #this temp gets data with an ID to use for next row joins
    DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollExit2;    
	SET @row_number:=0;
	CREATE TEMPORARY TABLE sptmp_EnrollExit2 AS
	select @row_number:=@row_number+1 ID
		,contactId 
        ,ProgramDetail
        ,Program
        ,enrolledDate
        ,exitDate
        ,exitStatusID
	from (
    select distinct contactId 
        ,ProgramDetail
        ,Program
        ,enrolledDate
        ,exitDate
        ,IF(exitStatusID=0,NULL,exitStatusID) exitStatusID
	from sptmp_EnrollExit1
    ) data
    order by contactId, enrolledDate, IFNULL(exitdate,'3000-12-31');
    
    #copy for joining back to itself
    DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollExit2Next;    
	CREATE TEMPORARY TABLE sptmp_EnrollExit2Next AS
    SELECT * FROM sptmp_EnrollExit2;
    
    CREATE INDEX idx_sptmp_EnrollExit2 on sptmp_EnrollExit2(contactid, id);
    CREATE INDEX idx_sptmp_EnrollExit2Next on sptmp_EnrollExit2Next(contactid, id);
    
    #joining the tables to determine "next row" and create an exit date if needed
    DROP TEMPORARY TABLE IF EXISTS sptmp_EnrollExit; 
    SET @row_number:=0;
	CREATE TEMPORARY TABLE sptmp_EnrollExit AS
    SELECT ID
		,contactId
        ,bannerGNumber
        ,Program
        ,ProgramDetail
        ,enrolledDate
        ,ExitDate
        ,CASE WHEN dataNextContactID IS NULL AND exitDate IS NOT NULL THEN 'Left PCC Links' 
				WHEN  dataNextContactID IS NOT NULL and ExitDate IS NOT NULL THEN 'Transitioned'
				ELSE 'None' END ExitType
		,exitKeyStatusReasonID
        ,exitReason
        ,secondaryReason
        ,exitNote
        ,CAST(NULL AS CHAR(100)) as SchoolDistrict
        ,CAST(NULL as CHAR(10)) keySchoolDistrictId
        ,CAST(NULL as CHAR(100)) studentDistrictNumber
        ,CAST(NULL AS CHAR(100)) as Coach
        ,CAST(NULL as CHAR(10)) keyResourceSpecialistId
	FROM(
    SELECT @row_number:=@row_number+1 ID
		,data.contactId
		,data.Program
        ,data.ProgramDetail
        ,data.enrolledDate
        ,contact.bannerGNumber
        ,dataNext.contactID dataNextContactID
        #if there is no exit date, but there is a "next" row
        #then take the enrolled date from the "next" row
        #if the exit date is greater than the next enrolled date, use the next enrolled date instead
        #else use the exit date
        ,CASE WHEN data.exitDate IS NULL THEN dataNext.enrolledDate
			WHEN dataNext.enrolledDate IS NULL THEN data.exitDate
            #if dataNext enrolled > exitDate and dataNext enrolled not the same as current enrolled...
            #if both enrolled the same, then that is handled by a pass further down
			WHEN data.exitDate > dataNext.enrolledDate and data.enrolledDate != dataNext.enrolledDate THEN dataNext.enrolledDate
            ELSE data.exitDate END  ExitDate
        ,keyStatusReason.keyStatusReasonID exitKeyStatusReasonID
        ,keyStatusReason.reasonText as exitReason
        ,fnGetSecondaryReason(data.exitStatusID) secondaryReason
		,exitStatus.statusNotes as exitNote
	FROM sptmp_EnrollExit2 data
		join contact on data.contactID = contact.contactID
		left outer join sptmp_EnrollExit2Next dataNext on data.contactId = dataNext.contactId
			and data.ID + 1 = dataNext.ID
		left outer join status exitStatus 
			on data.exitStatusID = exitStatus.StatusID
		left outer join statusReason
			on exitStatus.StatusID = statusReason.statusID
		left outer join keyStatusReason
			on keyStatusReason.keyStatusReasonID = statusReason.keyStatusReasonID
	ORDER BY data.contactId, data.enrolledDate
	) finalData;
    
	#update cleans up where two rows have the same enrolled date
    #due to imperfect matching above
	UPDATE sptmp_EnrollExit
    JOIN (SELECT data.contactId
		,data.Program
        ,data.ProgramDetail
        ,data.enrolledDate
        ,dataPrev.exitDate PrevExitDate
	FROM sptmp_EnrollExit2 data
		left outer join sptmp_EnrollExit2Next dataPrev on data.contactId = dataPrev.contactId
			and data.ProgramDetail= dataPrev.ProgramDetail
			and data.ID-1 = dataPrev.ID
	where data.enrolledDate = dataPrev.enrolledDate) data
		on sptmp_EnrollExit.contactId = data.contactId
			and sptmp_EnrollExit.program = data.program
            and sptmp_EnrollExit.ProgramDetail = data.ProgramDetail
            and sptmp_EnrollExit.enrolledDate = data.enrolledDate
    SET sptmp_EnrollExit.EnrolledDate = PrevExitDate;
 
	#now going to pull in appropriate school district and coach to the timeframe of each row
    #to flatten this out for easier reporting 
	DROP TEMPORARY TABLE IF EXISTS sptmp_SD1; 
	CREATE TEMPORARY TABLE sptmp_SD1 AS
    SELECT ID, substring_index(maxDateString,'|',-1) StatusID
    FROM(
	select sptmp_EnrollExit.ID
        ,MAX(concat(status.statusDate,'|', status.statusID)) maxDateString
	from sptmp_EnrollExit 
		join status on status.keyStatusID = (7) # SD status
		and undoneStatusID is null # status change hasnt been undone
		and (statusDate < sptmp_EnrollExit.exitDate
			or sptmp_EnrollExit.exitDate IS NULL)
		and sptmp_EnrollExit.contactId = status.contactId
	group by sptmp_EnrollExit.ID
		,sptmp_EnrollExit.contactId
		,sptmp_EnrollExit.Program
        ,sptmp_EnrollExit.ProgramDetail
        ,sptmp_EnrollExit.enrolledDate
        ,sptmp_EnrollExit.exitDate) data;
        
    CREATE INDEX idx_sptmp_SD1_StatusID on sptmp_SD1(StatusID);
    CREATE INDEX idx_sptmp_SD1_ID on sptmp_SD1(ID);
	
    UPDATE sptmp_EnrollExit
	JOIN sptmp_SD1 on sptmp_EnrollExit.ID = sptmp_SD1.ID
		JOIN statusSchoolDistrict 
			on sptmp_SD1.statusID = statusSchoolDistrict.statusID
		join keySchoolDistrict 
			on statusSchoolDistrict.keySchoolDistrictID = keySchoolDistrict.keySchoolDistrictID
     SET sptmp_EnrollExit.SchoolDistrict  = keySchoolDistrict.schoolDistrict
		,sptmp_EnrollExit.keySchoolDistrictId = statusSchoolDistrict.keySchoolDistrictID
        ,sptmp_EnrollExit.studentDistrictNumber = statusSchoolDistrict.studentDistrictNumber;
       
	DROP TEMPORARY TABLE IF EXISTS sptmp_Coach; 
	CREATE TEMPORARY TABLE sptmp_Coach AS
    SELECT ID, substring_index(maxDateString,'|',-1) StatusID
    FROM(
	select sptmp_EnrollExit.ID
        ,MAX(concat(status.statusDate,'|', status.statusID)) maxDateString
	from sptmp_EnrollExit 
		join status on status.keyStatusID = (6) # coach status
		and undoneStatusID is null # status change hasnt been undone
		and (statusDate < sptmp_EnrollExit.exitDate
			or sptmp_EnrollExit.exitDate IS NULL)
		and sptmp_EnrollExit.contactId = status.contactId
	group by sptmp_EnrollExit.ID
		,sptmp_EnrollExit.contactId
		,sptmp_EnrollExit.Program
        ,sptmp_EnrollExit.ProgramDetail
        ,sptmp_EnrollExit.enrolledDate
        ,sptmp_EnrollExit.exitDate) data;
        
    CREATE INDEX idx_sptmp_Coach_StatusID on sptmp_Coach(StatusID);
    CREATE INDEX idx_sptmp_Coach_ID on sptmp_Coach(ID);
	
    UPDATE sptmp_EnrollExit
	JOIN sptmp_Coach on sptmp_EnrollExit.ID = sptmp_Coach.ID
		JOIN statusResourceSpecialist 
			on sptmp_Coach.statusID = statusResourceSpecialist.statusID
		join keyResourceSpecialist 
			on statusResourceSpecialist.keyResourceSpecialistID = keyResourceSpecialist.keyResourceSpecialistID
     SET Coach = rsName, sptmp_EnrollExit.keyResourceSpecialistID = keyResourceSpecialist.keyResourceSpecialistID;
     
	#from this data, also going to create current state
    #for each contact
 
	#get the last entry per contact 
    DROP TEMPORARY TABLE IF EXISTS sptmp_CurrentEnrollExit1;
    
    CREATE TEMPORARY TABLE sptmp_CurrentEnrollExit1
    SELECT contactId, max(ID) ID 
    FROM sptmp_EnrollExit 
    GROUP BY contactId;

	CREATE INDEX idx_sptmp_EnrollExit on sptmp_EnrollExit(id);
	CREATE INDEX idx_sptmp_CurrentEnrollExit1 on sptmp_CurrentEnrollExit1(id);

    #get latest exit entries per contactid
    DROP TEMPORARY TABLE IF EXISTS sptmp_CurrentEnrollExit;
	CREATE TEMPORARY TABLE sptmp_CurrentEnrollExit AS        
    SELECT ee.*, CASE WHEN ee.exitDate IS NULL THEN IFNULL(ee.ProgramDetail, ee.Program) ELSE 'Exited' END CurrentStatus
    FROM sptmp_EnrollExit ee
		join sptmp_CurrentEnrollExit1 latest
			on ee.ID = latest.ID;

	CREATE INDEX idx_sptmp_EnrollExit_contact on sptmp_EnrollExit(contactId);
	CREATE INDEX idx_sptmp_CurrentEnrollExit_contact on sptmp_CurrentEnrollExit(contactId);
END//
DELIMITER ;
