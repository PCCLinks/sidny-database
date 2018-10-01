DELIMITER // 
DROP TRIGGER IF EXISTS `trbillingStudent_update`
//
DELIMITER // 
CREATE TRIGGER `trbillingStudent_update` AFTER UPDATE on billingStudent
FOR EACH ROW
BEGIN

IF (NEW.AdjustedDaysPerMonth != OLD.AdjustedDaysPerMonth) OR (LENGTH(IFNULL(NEW.AdjustedDaysPerMonth,'')) != LENGTH(IFNULL(OLD.AdjustedDaysPerMonth,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'AdjustedDaysPerMonth', old.AdjustedDaysPerMonth, new.AdjustedDaysPerMonth, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.AdjustedIndHours != OLD.AdjustedIndHours) OR (LENGTH(IFNULL(NEW.AdjustedIndHours,'')) != LENGTH(IFNULL(OLD.AdjustedIndHours,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'AdjustedIndHours', old.AdjustedIndHours, new.AdjustedIndHours, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.bannerGNumber != OLD.bannerGNumber) OR (LENGTH(IFNULL(NEW.bannerGNumber,'')) != LENGTH(IFNULL(OLD.bannerGNumber,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'bannerGNumber', old.bannerGNumber, new.bannerGNumber, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingEndDate != OLD.BillingEndDate) OR (LENGTH(IFNULL(NEW.BillingEndDate,'')) != LENGTH(IFNULL(OLD.BillingEndDate,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'BillingEndDate', old.BillingEndDate, new.BillingEndDate, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingNotes != OLD.BillingNotes) OR (LENGTH(IFNULL(NEW.BillingNotes,'')) != LENGTH(IFNULL(OLD.BillingNotes,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'BillingNotes', old.BillingNotes, new.BillingNotes, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingStartDate != OLD.BillingStartDate) OR (LENGTH(IFNULL(NEW.BillingStartDate,'')) != LENGTH(IFNULL(OLD.BillingStartDate,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'BillingStartDate', old.BillingStartDate, new.BillingStartDate, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingStatus != OLD.BillingStatus) OR (LENGTH(IFNULL(NEW.BillingStatus,'')) != LENGTH(IFNULL(OLD.BillingStatus,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'BillingStatus', old.BillingStatus, new.BillingStatus, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingStudentExitReasonCode != OLD.BillingStudentExitReasonCode) OR (LENGTH(IFNULL(NEW.BillingStudentExitReasonCode,'')) != LENGTH(IFNULL(OLD.BillingStudentExitReasonCode,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'BillingStudentExitReasonCode', old.BillingStudentExitReasonCode, new.BillingStudentExitReasonCode, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.BillingStudentID != OLD.BillingStudentID) OR (LENGTH(IFNULL(NEW.BillingStudentID,'')) != LENGTH(IFNULL(OLD.BillingStudentID,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'BillingStudentID', old.BillingStudentID, new.BillingStudentID, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CMPercent != OLD.CMPercent) OR (LENGTH(IFNULL(NEW.CMPercent,'')) != LENGTH(IFNULL(OLD.CMPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CMPercent', old.CMPercent, new.CMPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.ContactID != OLD.ContactID) OR (LENGTH(IFNULL(NEW.ContactID,'')) != LENGTH(IFNULL(OLD.ContactID,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'ContactID', old.ContactID, new.ContactID, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CorrectedBilledAmount != OLD.CorrectedBilledAmount) OR (LENGTH(IFNULL(NEW.CorrectedBilledAmount,'')) != LENGTH(IFNULL(OLD.CorrectedBilledAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CorrectedBilledAmount', old.CorrectedBilledAmount, new.CorrectedBilledAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CorrectedBilledUnits != OLD.CorrectedBilledUnits) OR (LENGTH(IFNULL(NEW.CorrectedBilledUnits,'')) != LENGTH(IFNULL(OLD.CorrectedBilledUnits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CorrectedBilledUnits', old.CorrectedBilledUnits, new.CorrectedBilledUnits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CorrectedOverageAmount != OLD.CorrectedOverageAmount) OR (LENGTH(IFNULL(NEW.CorrectedOverageAmount,'')) != LENGTH(IFNULL(OLD.CorrectedOverageAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CorrectedOverageAmount', old.CorrectedOverageAmount, new.CorrectedOverageAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CorrectedOverageUnits != OLD.CorrectedOverageUnits) OR (LENGTH(IFNULL(NEW.CorrectedOverageUnits,'')) != LENGTH(IFNULL(OLD.CorrectedOverageUnits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CorrectedOverageUnits', old.CorrectedOverageUnits, new.CorrectedOverageUnits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CreatedBy != OLD.CreatedBy) OR (LENGTH(IFNULL(NEW.CreatedBy,'')) != LENGTH(IFNULL(OLD.CreatedBy,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CreatedBy', old.CreatedBy, new.CreatedBy, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.CreditsEntered != OLD.CreditsEntered) OR (LENGTH(IFNULL(NEW.CreditsEntered,'')) != LENGTH(IFNULL(OLD.CreditsEntered,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'CreditsEntered', old.CreditsEntered, new.CreditsEntered, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.DateCreated != OLD.DateCreated) OR (LENGTH(IFNULL(NEW.DateCreated,'')) != LENGTH(IFNULL(OLD.DateCreated,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'DateCreated', old.DateCreated, new.DateCreated, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.DistrictID != OLD.DistrictID) OR (LENGTH(IFNULL(NEW.DistrictID,'')) != LENGTH(IFNULL(OLD.DistrictID,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'DistrictID', old.DistrictID, new.DistrictID, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.EnrolledDate != OLD.EnrolledDate) OR (LENGTH(IFNULL(NEW.EnrolledDate,'')) != LENGTH(IFNULL(OLD.EnrolledDate,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'EnrolledDate', old.EnrolledDate, new.EnrolledDate, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.ErrorMessage != OLD.ErrorMessage) OR (LENGTH(IFNULL(NEW.ErrorMessage,'')) != LENGTH(IFNULL(OLD.ErrorMessage,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'ErrorMessage', old.ErrorMessage, new.ErrorMessage, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.ExitDate != OLD.ExitDate) OR (LENGTH(IFNULL(NEW.ExitDate,'')) != LENGTH(IFNULL(OLD.ExitDate,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'ExitDate', old.ExitDate, new.ExitDate, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.exitStatusReasonID != OLD.exitStatusReasonID) OR (LENGTH(IFNULL(NEW.exitStatusReasonID,'')) != LENGTH(IFNULL(OLD.exitStatusReasonID,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'exitStatusReasonID', old.exitStatusReasonID, new.exitStatusReasonID, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.FinalBilledAmount != OLD.FinalBilledAmount) OR (LENGTH(IFNULL(NEW.FinalBilledAmount,'')) != LENGTH(IFNULL(OLD.FinalBilledAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'FinalBilledAmount', old.FinalBilledAmount, new.FinalBilledAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.FinalBilledUnits != OLD.FinalBilledUnits) OR (LENGTH(IFNULL(NEW.FinalBilledUnits,'')) != LENGTH(IFNULL(OLD.FinalBilledUnits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'FinalBilledUnits', old.FinalBilledUnits, new.FinalBilledUnits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.FinalOverageAmount != OLD.FinalOverageAmount) OR (LENGTH(IFNULL(NEW.FinalOverageAmount,'')) != LENGTH(IFNULL(OLD.FinalOverageAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'FinalOverageAmount', old.FinalOverageAmount, new.FinalOverageAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.FinalOverageUnits != OLD.FinalOverageUnits) OR (LENGTH(IFNULL(NEW.FinalOverageUnits,'')) != LENGTH(IFNULL(OLD.FinalOverageUnits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'FinalOverageUnits', old.FinalOverageUnits, new.FinalOverageUnits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.GeneratedBilledAmount != OLD.GeneratedBilledAmount) OR (LENGTH(IFNULL(NEW.GeneratedBilledAmount,'')) != LENGTH(IFNULL(OLD.GeneratedBilledAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'GeneratedBilledAmount', old.GeneratedBilledAmount, new.GeneratedBilledAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.GeneratedBilledUnits != OLD.GeneratedBilledUnits) OR (LENGTH(IFNULL(NEW.GeneratedBilledUnits,'')) != LENGTH(IFNULL(OLD.GeneratedBilledUnits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'GeneratedBilledUnits', old.GeneratedBilledUnits, new.GeneratedBilledUnits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.GeneratedOverageAmount != OLD.GeneratedOverageAmount) OR (LENGTH(IFNULL(NEW.GeneratedOverageAmount,'')) != LENGTH(IFNULL(OLD.GeneratedOverageAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'GeneratedOverageAmount', old.GeneratedOverageAmount, new.GeneratedOverageAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.GeneratedOverageUnits != OLD.GeneratedOverageUnits) OR (LENGTH(IFNULL(NEW.GeneratedOverageUnits,'')) != LENGTH(IFNULL(OLD.GeneratedOverageUnits,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'GeneratedOverageUnits', old.GeneratedOverageUnits, new.GeneratedOverageUnits, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.IncludeFlag != OLD.IncludeFlag) OR (LENGTH(IFNULL(NEW.IncludeFlag,'')) != LENGTH(IFNULL(OLD.IncludeFlag,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'IncludeFlag', old.IncludeFlag, new.IncludeFlag, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.InterGroupPercent != OLD.InterGroupPercent) OR (LENGTH(IFNULL(NEW.InterGroupPercent,'')) != LENGTH(IFNULL(OLD.InterGroupPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'InterGroupPercent', old.InterGroupPercent, new.InterGroupPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.LargeGroupPercent != OLD.LargeGroupPercent) OR (LENGTH(IFNULL(NEW.LargeGroupPercent,'')) != LENGTH(IFNULL(OLD.LargeGroupPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'LargeGroupPercent', old.LargeGroupPercent, new.LargeGroupPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.MaxCreditsPerTerm != OLD.MaxCreditsPerTerm) OR (LENGTH(IFNULL(NEW.MaxCreditsPerTerm,'')) != LENGTH(IFNULL(OLD.MaxCreditsPerTerm,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'MaxCreditsPerTerm', old.MaxCreditsPerTerm, new.MaxCreditsPerTerm, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.MaxDaysPerBillingPeriod != OLD.MaxDaysPerBillingPeriod) OR (LENGTH(IFNULL(NEW.MaxDaysPerBillingPeriod,'')) != LENGTH(IFNULL(OLD.MaxDaysPerBillingPeriod,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'MaxDaysPerBillingPeriod', old.MaxDaysPerBillingPeriod, new.MaxDaysPerBillingPeriod, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.MaxDaysPerMonth != OLD.MaxDaysPerMonth) OR (LENGTH(IFNULL(NEW.MaxDaysPerMonth,'')) != LENGTH(IFNULL(OLD.MaxDaysPerMonth,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'MaxDaysPerMonth', old.MaxDaysPerMonth, new.MaxDaysPerMonth, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.MaxDaysPerYear != OLD.MaxDaysPerYear) OR (LENGTH(IFNULL(NEW.MaxDaysPerYear,'')) != LENGTH(IFNULL(OLD.MaxDaysPerYear,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'MaxDaysPerYear', old.MaxDaysPerYear, new.MaxDaysPerYear, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.PIDM != OLD.PIDM) OR (LENGTH(IFNULL(NEW.PIDM,'')) != LENGTH(IFNULL(OLD.PIDM,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'PIDM', old.PIDM, new.PIDM, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.PostBillCorrectedBilledAmount != OLD.PostBillCorrectedBilledAmount) OR (LENGTH(IFNULL(NEW.PostBillCorrectedBilledAmount,'')) != LENGTH(IFNULL(OLD.PostBillCorrectedBilledAmount,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'PostBillCorrectedBilledAmount', old.PostBillCorrectedBilledAmount, new.PostBillCorrectedBilledAmount, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.Program != OLD.Program) OR (LENGTH(IFNULL(NEW.Program,'')) != LENGTH(IFNULL(OLD.Program,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'Program', old.Program, new.Program, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.ReviewNotes != OLD.ReviewNotes) OR (LENGTH(IFNULL(NEW.ReviewNotes,'')) != LENGTH(IFNULL(OLD.ReviewNotes,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'ReviewNotes', old.ReviewNotes, new.ReviewNotes, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.ReviewWithCoachFlag != OLD.ReviewWithCoachFlag) OR (LENGTH(IFNULL(NEW.ReviewWithCoachFlag,'')) != LENGTH(IFNULL(OLD.ReviewWithCoachFlag,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'ReviewWithCoachFlag', old.ReviewWithCoachFlag, new.ReviewWithCoachFlag, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.SmGroupPercent != OLD.SmGroupPercent) OR (LENGTH(IFNULL(NEW.SmGroupPercent,'')) != LENGTH(IFNULL(OLD.SmGroupPercent,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'SmGroupPercent', old.SmGroupPercent, new.SmGroupPercent, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
IF (NEW.Term != OLD.Term) OR (LENGTH(IFNULL(NEW.Term,'')) != LENGTH(IFNULL(OLD.Term,''))) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
    VALUES ('billingStudent', 'BillingStudentID', new.BillingStudentID, 'Term', old.Term, new.Term, 'UPDATE', now(), NEW.LastUpdatedBy);
 END IF;
 
 
 END
 //