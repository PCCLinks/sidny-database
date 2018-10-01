DELIMITER // 
DROP TRIGGER IF EXISTS `trbillingStudentItem_update`
//
DELIMITER // 
CREATE TRIGGER `trbillingStudentItem_update` AFTER UPDATE on billingStudentItem
FOR EACH ROW
BEGIN
 
 IF (NEW.Attendance != OLD.Attendance) OR (LENGTH(IFNULL(NEW.Attendance,'')) != LENGTH(IFNULL(OLD.Attendance,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'Attendance', old.Attendance, new.Attendance, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingStudentID != OLD.BillingStudentID) OR (LENGTH(IFNULL(NEW.BillingStudentID,'')) != LENGTH(IFNULL(OLD.BillingStudentID,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'BillingStudentID', old.BillingStudentID, new.BillingStudentID, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingStudentItemID != OLD.BillingStudentItemID) OR (LENGTH(IFNULL(NEW.BillingStudentItemID,'')) != LENGTH(IFNULL(OLD.BillingStudentItemID,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'BillingStudentItemID', old.BillingStudentItemID, new.BillingStudentItemID, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CreatedBy != OLD.CreatedBy) OR (LENGTH(IFNULL(NEW.CreatedBy,'')) != LENGTH(IFNULL(OLD.CreatedBy,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'CreatedBy', old.CreatedBy, new.CreatedBy, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.Credits != OLD.Credits) OR (LENGTH(IFNULL(NEW.Credits,'')) != LENGTH(IFNULL(OLD.Credits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'Credits', old.Credits, new.Credits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CRN != OLD.CRN) OR (LENGTH(IFNULL(NEW.CRN,'')) != LENGTH(IFNULL(OLD.CRN,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'CRN', old.CRN, new.CRN, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CRSE != OLD.CRSE) OR (LENGTH(IFNULL(NEW.CRSE,'')) != LENGTH(IFNULL(OLD.CRSE,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'CRSE', old.CRSE, new.CRSE, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.DateCreated != OLD.DateCreated) OR (LENGTH(IFNULL(NEW.DateCreated,'')) != LENGTH(IFNULL(OLD.DateCreated,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'DateCreated', old.DateCreated, new.DateCreated, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.IncludeFlag != OLD.IncludeFlag) OR (LENGTH(IFNULL(NEW.IncludeFlag,'')) != LENGTH(IFNULL(OLD.IncludeFlag,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'IncludeFlag', old.IncludeFlag, new.IncludeFlag, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.IndPercent != OLD.IndPercent) OR (LENGTH(IFNULL(NEW.IndPercent,'')) != LENGTH(IFNULL(OLD.IndPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'IndPercent', old.IndPercent, new.IndPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.InterPercent != OLD.InterPercent) OR (LENGTH(IFNULL(NEW.InterPercent,'')) != LENGTH(IFNULL(OLD.InterPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'InterPercent', old.InterPercent, new.InterPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.LargePercent != OLD.LargePercent) OR (LENGTH(IFNULL(NEW.LargePercent,'')) != LENGTH(IFNULL(OLD.LargePercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'LargePercent', old.LargePercent, new.LargePercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.MaxPossibleAttendance != OLD.MaxPossibleAttendance) OR (LENGTH(IFNULL(NEW.MaxPossibleAttendance,'')) != LENGTH(IFNULL(OLD.MaxPossibleAttendance,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'MaxPossibleAttendance', old.MaxPossibleAttendance, new.MaxPossibleAttendance, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.Scenario != OLD.Scenario) OR (LENGTH(IFNULL(NEW.Scenario,'')) != LENGTH(IFNULL(OLD.Scenario,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'Scenario', old.Scenario, new.Scenario, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.SmallPercent != OLD.SmallPercent) OR (LENGTH(IFNULL(NEW.SmallPercent,'')) != LENGTH(IFNULL(OLD.SmallPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'SmallPercent', old.SmallPercent, new.SmallPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.SUBJ != OLD.SUBJ) OR (LENGTH(IFNULL(NEW.SUBJ,'')) != LENGTH(IFNULL(OLD.SUBJ,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'SUBJ', old.SUBJ, new.SUBJ, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.TakenPreviousTerm != OLD.TakenPreviousTerm) OR (LENGTH(IFNULL(NEW.TakenPreviousTerm,'')) != LENGTH(IFNULL(OLD.TakenPreviousTerm,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'TakenPreviousTerm', old.TakenPreviousTerm, new.TakenPreviousTerm, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.Title != OLD.Title) OR (LENGTH(IFNULL(NEW.Title,'')) != LENGTH(IFNULL(OLD.Title,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudentItem', 'BillingStudentItemID', new.BillingStudentItemID, 'Title', old.Title, new.Title, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
 
 END