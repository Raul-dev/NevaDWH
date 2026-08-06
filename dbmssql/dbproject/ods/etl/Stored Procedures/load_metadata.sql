CREATE PROCEDURE [etl].[load_metadata]
    @SessionId         BIGINT = NULL,
    @BufferHistoryMode TINYINT = 0,
    @RowCount          INT = NULL OUTPUT,
    @ErrorMessage      VARCHAR(4000) = NULL OUTPUT
AS
BEGIN
    SET XACT_ABORT OFF
    SET CONCAT_NULL_YIELDS_NULL ON
    SET NOCOUNT ON

    DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @AuditProcEnable nvarchar(256)
    SET @AuditProcEnable = [etl].[fn_GetSettingValue]('AuditProcAll')
    IF @AuditProcEnable IS NOT NULL
    BEGIN
        IF OBJECT_ID('tempdb..#LogProc') IS NULL
            CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
        SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
        SET @ProcedureParams =
            '@SessionId='+ISNULL(LTRIM(STR(@SessionId)),'NULL') + ', ' +
            '@BufferHistoryMode='+ISNULL(LTRIM(STR(@BufferHistoryMode)),'NULL')
        EXEC [audit].[sp_LogStart] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
    END

    DECLARE @MinDate datetime2(4) = DATEFROMPARTS(1900, 01, 01),
        @UpdateDate datetime2(4),
        @BufferHistoryDays int

    SET @BufferHistoryDays = IIF(@BufferHistoryMode = 2, 10, 30)

    BEGIN TRY
    BEGIN TRANSACTION
        DECLARE @tmp_metadata AS TABLE(
            [Namespace]        NVARCHAR(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
            [NamespaceVersion] NVARCHAR(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
            [MessageBody]      NVARCHAR(MAX) COLLATE Cyrillic_General_CI_AS NULL,
            [BufferId]         BIGINT,
            [SessionId]        BIGINT,
            [MessageId]        UNIQUEIDENTIFIER,
            [MessageKey]       NVARCHAR(256) COLLATE Cyrillic_General_CI_AS NULL,
            [MetaAdapterId]    TINYINT
        );

        WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.3/MDClasses','http://v8.1c.ru/8.3/xcf/readable' as xr)
        INSERT @tmp_metadata ([MessageBody], [BufferId], [SessionId], [MessageId], [MessageKey], [MetaAdapterId], [Namespace], [NamespaceVersion])
        SELECT
            [MessageBody], [BufferId], [SessionId], [MessageId], [MessageKey], [MetaAdapterId],
            [Namespace] = CASE [MetaAdapterId] WHEN 4
                                THEN JSON_VALUE([MessageBody],'$."Реквизиты"[0]."ПространствоИменИсходное"')
                            WHEN 1 THEN 'https://nevadwh.ru' + '/' + COALESCE(CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Document/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
            CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/InformationRegister/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
            CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Catalog/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'))
                            ELSE 'unknown'
                        END,
            [NamespaceVersion] = CASE [MetaAdapterId] WHEN 4
                                THEN JSON_VALUE([MessageBody],'$."Реквизиты"[0]."ПространствоИменСВерсией"')
                            WHEN 1 THEN 'https://nevadwh.ru' + '/' + COALESCE(CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Document/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
            CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/InformationRegister/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
            CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Catalog/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)')) + '/version1'
                            ELSE 'unknown'
                        END
        FROM [mq].[MetadataBuffer] WITH (XLOCK)
        WHERE [IsError] = 0;
        SET @RowCount = @@ROWCOUNT

        IF (@RowCount = 0)
        BEGIN
            COMMIT
            RETURN 0
        END

        INSERT INTO [etl].[Metadata] ([NKey], [Namespace], [NamespaceVersion], [MessageBody], [MetaAdapterId])
        SELECT
            CAST(SUBSTRING(HASHBYTES('SHA2_256', COALESCE(p.[MessageBody], '')), 0, 32) AS UNIQUEIDENTIFIER) AS NKey,
            [Namespace], [NamespaceVersion], p.[MessageBody], p.[MetaAdapterId]
        FROM (
            SELECT * FROM @tmp_metadata
            WHERE [BufferId] IN (
                SELECT MAX([BufferId]) FROM @tmp_metadata
                GROUP BY [NamespaceVersion]
            )
        ) p
        WHERE NOT EXISTS (SELECT 1 FROM [etl].[Metadata] l WHERE l.[NamespaceVersion] = p.[NamespaceVersion])

        UPDATE m
            SET m.[MessageBody] = p.[MessageBody]
        FROM [etl].[Metadata] m
        INNER JOIN (
            SELECT [NamespaceVersion], [MessageBody] FROM @tmp_metadata
            WHERE [BufferId] IN (
                SELECT MAX([BufferId]) FROM @tmp_metadata
                GROUP BY [NamespaceVersion]
            )
        ) p ON m.[NamespaceVersion] = p.[NamespaceVersion]

        IF @BufferHistoryMode = 1 AND NOT EXISTS (SELECT 1 FROM [mq].[MetadataBuffer] WHERE [IsError] = 1)
        BEGIN
            DELETE b
            FROM [mq].[MetadataBuffer] b
            INNER JOIN @tmp_metadata t ON b.[BufferId] = t.[BufferId]
        END
        ELSE
        BEGIN
            UPDATE b SET [UpdatedAt] = @UpdateDate
            FROM [mq].[MetadataBuffer] AS b
            INNER JOIN @tmp_metadata l ON l.[BufferId] = b.[BufferId]

            IF @BufferHistoryMode >= 2 AND NOT EXISTS (SELECT 1 FROM [mq].[MetadataBuffer] WHERE [IsError] = 1)
                DELETE b
                FROM [mq].[MetadataBuffer] b
                WHERE DATEDIFF(DD, @UpdateDate, [UpdatedAt]) > @BufferHistoryDays
        END

        EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount

    COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE()

        IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0
        BEGIN
             ROLLBACK TRANSACTION
        END
        INSERT [mq].[SessionLog] ([SessionId], [SessionStateId], [ErrorMessage])
        SELECT COALESCE(@SessionId, (SELECT MAX([SessionId]) FROM [mq].[Session])),
            4,
            'Table MetadataBuffer. Error: ' + @ErrorMessage

        IF NOT @ErrorMessage LIKE '%deadlock%'
            UPDATE b SET [IsError] = 1
            FROM [mq].[MetadataBuffer] b
            INNER JOIN @tmp_metadata t ON b.[BufferId] = t.[BufferId]

        SET @RowCount = @@TRANCOUNT
        EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

        EXEC [audit].[sp_Print] @ErrorMessage, 4
        RETURN -1
    END CATCH
END
