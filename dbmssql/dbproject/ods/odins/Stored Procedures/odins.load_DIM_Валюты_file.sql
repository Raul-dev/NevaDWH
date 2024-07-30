CREATE PROCEDURE [odins].[load_DIM_Валюты_file]
    @FileQueueID  bigint = NULL,
    @FileOverride nvarchar(4000) = NULL,
    @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
    SET @ProcedureParams =
        '@FileQueueID=' + ISNULL(LTRIM(STR(@FileQueueID)),'NULL') + ', ' +
        '@FileOverride=' + ISNULL('''' +CAST(@FileOverride AS varchar(19) ) + '''','NULL')

    EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

--SET TRANSACTION ISOLATION LEVEL READ COMMITTED
--SET DEADLOCK_PRIORITY LOW
DECLARE @FilePath nvarchar(4000)
DECLARE @FormatFilePath nvarchar(4000)
DECLARE @SqlCmd nvarchar(Max), @IsSingleFile bit = 0
DECLARE @MsgKey nvarchar(256) = 'CatalogObject.Валюты';
DECLARE @IdError bigint = 0

BEGIN TRY

        IF NOT @FileQueueID IS NULL OR LEN(ISNULL(@FileOverride,'')) > 0
        BEGIN
            SET @IsSingleFile = 1
            IF LEN(ISNULL(@FileOverride,'')) > 0
                SET @FileQueueID = 0
            ELSE
            BEGIN
                SELECT @ErrorMessage = error_msg, @IdError = filequeue_id FROM [dbo].[filequeue] WHERE state_id = 3
                IF @IdError <> 0
                    RAISERROR( N'Загрузка FileQueueID=[%d], Вызвала ошибку [%s]. Дальнейшие загрузки остановлены.', 16, 1, @IdError, @ErrorMessage)
            END
        END
        ELSE
        BEGIN
            SET @FileQueueID = 0
            IF NOT EXISTS(SELECT TOP 1 filequeue_id FROM [dbo].[filequeue]
                WHERE msg_key = @MsgKey AND NOT [filename] IS NULL AND state_id = 1 AND (state_id >= @FileQueueID ))
            BEGIN 
                EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = 0, @ProcedureInfo = 'Not exists filequeue_id'
                RETURN 0
            END
        END

        WHILE (NOT @FileQueueID IS NULL )
        BEGIN
            SELECT @FileQueueID = (SELECT TOP 1 filequeue_id FROM [dbo].[filequeue]
            WHERE msg_key = @MsgKey AND NOT [filename] IS NULL AND state_id = 1 AND  (filequeue_id >= @FileQueueID AND @IsSingleFile = 0 OR @IsSingleFile = 1 AND filequeue_id = @FileQueueID) ORDER BY filequeue_id ASC )

            SELECT @FilePath = filefolder + '\' + [filename],
                @FormatFilePath= filefolder + '\' + 'format.xml'
            FROM [dbo].[filequeue] WHERE filequeue_id = @FileQueueID

            IF @IsSingleFile = 1 AND NOT @FileOverride IS NULL
            BEGIN
                SET @FilePath = @FileOverride
                SET @FormatFilePath= LEFT(@FileOverride, LEN(@FileOverride) - CHARINDEX('\', REVERSE(@FileOverride))+1) + 'format.xml' 
            END

            IF NOT @FilePath IS NULL
            BEGIN

                TRUNCATE TABLE staging.DIM_Валюты

                SELECT @SqlCmd = N';WITH XMLNAMESPACES (DEFAULT ''http://v8.1c.ru/8.1/data/enterprise/current-config'', ''http://www.w3.org/2001/XMLSchema-instance'' as xsi)
                INSERT staging.DIM_Валюты(nkey, [DIM_Валюты.Представления], [RefID], [DeletionMark], [Code], [Description], [ЗагружаетсяИзИнтернета], [НаименованиеПолное], [Наценка], [ОсновнаяВалюта], [ПараметрыПрописи], [ФормулаРасчетаКурса], [СпособУстановкиКурса], dt_update)
                SELECT
                    [nkey] = X.C.value(''(Ref/text())[1]'', ''uniqueidentifier'') ,
                    [DIM_Валюты.Представления] = X.C.query(''declare default element namespace "http://v8.1c.ru/8.1/data/enterprise/current-config";Представления''),
                    [RefID] = X.C.value(''(Ref/text())[1]'', ''uniqueidentifier''),
                    [DeletionMark] = X.C.value(''(DeletionMark/text())[1]'', ''bit''),
                    [Code] = X.C.value(''(Code/text())[1]'', ''varchar(128)''),
                    [Description] = X.C.value(''(Description/text())[1]'', ''varchar(128)''),
                    [ЗагружаетсяИзИнтернета] = X.C.value(''(ЗагружаетсяИзИнтернета/text())[1]'', ''bit''),
                    [НаименованиеПолное] = X.C.value(''(НаименованиеПолное/text())[1]'', ''varchar(50)''),
                    [Наценка] = X.C.value(''(Наценка/text())[1]'', ''decimal(10,2)''),
                    [ОсновнаяВалюта] = X.C.value(''(ОсновнаяВалюта/text())[1]'', ''varchar(36)''),
                    [ПараметрыПрописи] = X.C.value(''(ПараметрыПрописи/text())[1]'', ''varchar(200)''),
                    [ФормулаРасчетаКурса] = X.C.value(''(ФормулаРасчетаКурса/text())[1]'', ''varchar(100)''),
                    [СпособУстановкиКурса] = X.C.value(''(СпособУстановкиКурса/text())[1]'', ''varchar(500)''),
                    [dt_update] = GetDate()
                FROM OPENROWSET(BULK ''' + @FilePath + ''', SINGLE_BLOB, CODEPAGE = ''65001'') AS T(File_xml)
                    CROSS APPLY (VALUES (CAST(T.File_xml AS xml)) ) AS T2(XMLFromFile)
                    CROSS APPLY T2.XMLFromFile.nodes(''/Data/Реквизиты/CatalogObject.Валюты'') AS X(C);
                '
                EXEC [audit].[sp_Print] @SqlCmd, 2
                EXEC dbo.sp_executesql @SqlCmd

                DELETE src
                    FROM staging.DIM_Валюты src
                    INNER JOIN (
                        SELECT nkey, id = MAX(id) FROM staging.DIM_Валюты
                        GROUP BY nkey
                        HAVING Count(*) > 1
                    ) dbl ON dbl.nkey = src.nkey AND src.id < dbl.id

                SET TRANSACTION ISOLATION LEVEL READ COMMITTED
                BEGIN TRANSACTION
                    EXEC [odins].[load_DIM_Валюты_staging]
                    UPDATE [dbo].[filequeue] SET state_id = 2, dt_update = GetDate()
                    WHERE  filequeue_id = @FileQueueID
                COMMIT
            END
            IF @IsSingleFile = 1
                BREAK
        END
    SET @RowCount = @@ROWCOUNT
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount

END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()
    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    IF @IdError = 0
        UPDATE [dbo].[filequeue] SET state_id = 3, [error_msg] = @ErrorMessage, [dt_update] = GetDate()
        WHERE [filequeue_id] = @FileQueueID

    SET @RowCount = @@ROWCOUNT
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
    RETURN -1
END CATCH

END

GO
