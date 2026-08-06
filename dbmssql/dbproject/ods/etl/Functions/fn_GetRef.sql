
CREATE FUNCTION [etl].[fn_GetRef](@var XML, @Name VARCHAR(128))
RETURNS UNIQUEIDENTIFIER
WITH SCHEMABINDING
AS
BEGIN
    RETURN CAST(@var.value('declare default element namespace "http://v8.1c.ru/8.1/data/enterprise/current-config"; (/Data/Реквизиты/*[local-name(.)=sql:variable("@Name")]/Ref/text())[1]', 'varchar(36)') AS UNIQUEIDENTIFIER)
END;
