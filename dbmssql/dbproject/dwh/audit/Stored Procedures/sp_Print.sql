/*
[audit].[sp_Print] @StrPrint = ' SELECT * FROM Security '
[audit].[sp_Print] 'ds', 8
*/

CREATE   PROCEDURE [audit].[sp_Print]
    @StrPrint        nvarchar(max),
    @PrintLevel     int = 1 -- 1-Debug, 2-Info, 3-Warning, 4-Exception, 5-Test, 6-NotPrint
AS
BEGIN
    IF @PrintLevel >= 6
        return 0
    DECLARE @AuditPrintLevel int
    SELECT @AuditPrintLevel = ISNULL([dbo].[fn_GetSettingInt]('AuditPrintLevel'), 0)

    IF @PrintLevel < @AuditPrintLevel
        return 0

    DECLARE @StrTmp        nvarchar(4000)
    DECLARE @StrPart int
    SET @StrPart = 3500
    DECLARE @StrLen int
    SET @StrLen  = LEN(@StrPrint)
    DECLARE @EndPart int
    DECLARE @StrPrintTmp nvarchar(MAX)

    WHILE @StrLen > 0
        BEGIN 
            IF @StrLen <= @StrPart 
                BEGIN
                    print @StrPrint
                    BREAK
                END
            SET @StrTmp = LEFT(@StrPrint, @StrPart)
            SET @StrPrintTmp = RIGHT(@StrPrint, @StrLen - LEN(@StrTmp))
            SELECT @EndPart = CHARINDEX(CHAR(13), @StrPrintTmp) +1
            SET @StrTmp = @StrTmp + LEFT(@StrPrintTmp, @EndPart)
            Print @StrTmp        

            SET @StrPrint = RIGHT(@StrPrint, @StrLen - LEN(@StrTmp))
            SET @StrLen  = LEN(@StrPrint)
        END 
END