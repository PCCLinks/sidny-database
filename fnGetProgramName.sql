DELIMITER $$
CREATE FUNCTION `fnGetProgramName`(paramProgram varchar(50)) RETURNS varchar(50) CHARSET latin1
return case when lower(paramProgram) = 'gtc' then 'GtC'
				when lower(paramProgram) in ('ytc', 'yes', 'map') then 'YtC' 
				else 'na' end$$
DELIMITER ;
