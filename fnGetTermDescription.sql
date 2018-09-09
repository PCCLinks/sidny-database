DELIMITER $$
CREATE DEFINER=`root`@`10.14.%` FUNCTION `fnGetTermDescription`(paramTerm INT(11)) RETURNS varchar(25) CHARSET latin1
BEGIN
	return concat(paramTerm, case right(paramTerm,1)
								when 1 then '-Winter'
								when 2 then '-Spring'
			                    when 3 then '-Summer'
			                    when 4 then '-Fall' end);

END$$
DELIMITER ;
