
CREATE   FUNCTION dbo.fn_GetRef(@var xml, @Name varchar(128))
  RETURNS uniqueidentifier 
  with schemabinding
  AS
BEGIN

    RETURN CAST(@var.value('declare default element namespace "http://v8.1c.ru/8.1/data/enterprise/current-config"; (/Data/Реквизиты/*[local-name(.)=sql:variable("@Name")]/Ref/text())[1]', 'varchar(36)') AS uniqueidentifier )

END;