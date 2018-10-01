
 
 SELECT concat('INSERT INTO auditLog(tablename, idcolumnname, idvalue, columnname, oldvalue, newvalue, action, changeddate, changedby)
	VALUES (''', c.TABLE_NAME, ''',''', k.COLUMN_NAME, ''', NEW.', k.COLUMN_NAME, ',''', c.COLUMN_NAME, ''', NULL, new.', c.COLUMN_NAME, ', ''INSERT'', now(), current_user());
') Entry
FROM information_schema.COLUMNS c
	join information_schema.KEY_COLUMN_USAGE k on c.TABLE_NAME = k.TABLE_NAME
WHERE c.TABLE_NAME='billingStudent' and c.TABLE_SCHEMA = 'sidny'
	and k.constraint_schema = 'sidny'
    and k.constraint_name = 'primary'
ORDER BY c.COLUMN_NAME;


 SELECT concat('IF (NEW.', c.COLUMN_NAME, ' != OLD.', c.COLUMN_NAME,') OR (LENGTH(IFNULL(NEW.', c.COLUMN_NAME, ','''')) != LENGTH(IFNULL(OLD.', c.COLUMN_NAME,',''''))) THEN
   INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
   VALUES (''', c.TABLE_NAME,''', ''', k.COLUMN_NAME, ''', new.', k.COLUMN_NAME, ', ''', c.COLUMN_NAME, ''', old.', c.COLUMN_NAME, ', new.', c.COLUMN_NAME, ', ''UPDATE'', now(), NEW.LastUpdatedBy);
END IF;
')
FROM information_schema.COLUMNS c
	join information_schema.KEY_COLUMN_USAGE k on c.TABLE_NAME = k.TABLE_NAME
WHERE c.TABLE_NAME='billingStudentItem' and c.TABLE_SCHEMA = 'sidny'
	and k.constraint_schema = 'sidny'
    and k.constraint_name = 'primary'
    and c.COLUMN_NAME NOT IN ('LastUpdatedBy', 'DateLastUpdated')
ORDER BY c.COLUMN_NAME;



 SELECT concat('IF (NEW.', c.COLUMN_NAME, ' != OLD.', c.COLUMN_NAME,') OR (NEW.', c.COLUMN_NAME, ' IS NULL AND OLD.', c.COLUMN_NAME,' IS NOT NULL) OR (NEW.', c.COLUMN_NAME, ' IS NOT NULL AND OLD.', c.COLUMN_NAME,' IS NULL) THEN
    INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
   VALUES (''', c.TABLE_NAME,''', ''', k.COLUMN_NAME, ''', new.', k.COLUMN_NAME, ', ''', c.COLUMN_NAME, ''', old.', c.COLUMN_NAME, ', new.', c.COLUMN_NAME, ', ''UPDATE'', now(), current_user());
END IF;
')
FROM information_schema.COLUMNS c
	join information_schema.KEY_COLUMN_USAGE k on c.TABLE_NAME = k.TABLE_NAME
WHERE c.TABLE_NAME='enrichmentProgramContact' and c.TABLE_SCHEMA = 'sidny'
	and k.constraint_schema = 'sidny'
    and k.constraint_name = 'primary'
ORDER BY c.COLUMN_NAME;
 
 
 
 SELECT concat('IF (NEW.', c.COLUMN_NAME, ' != OLD.', c.COLUMN_NAME,') THEN
   INSERT INTO auditLog(tableName, idColumnName, idValue, columnName, oldValue, newValue, action, changedDate, changedBy)
   VALUES (''', c.TABLE_NAME,''', ''', k.COLUMN_NAME, ''', new.', k.COLUMN_NAME, ', ''', c.COLUMN_NAME, ''', old.', c.COLUMN_NAME, ', new.', c.COLUMN_NAME, ', ''UPDATE'', now(), current_user());
END IF;
')
FROM information_schema.COLUMNS c
	join information_schema.KEY_COLUMN_USAGE k on c.TABLE_NAME = k.TABLE_NAME
WHERE c.TABLE_NAME='enrichmentProgram' and c.TABLE_SCHEMA = 'sidny'
	and k.constraint_schema = 'sidny'
    and k.constraint_name = 'primary'
ORDER BY c.COLUMN_NAME;
