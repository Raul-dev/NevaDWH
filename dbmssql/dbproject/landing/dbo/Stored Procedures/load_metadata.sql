﻿CREATE PROCEDURE [dbo].[load_metadata]
    @session_id   int = NULL,
    @RowCount     int = NULL OUTPUT,
    @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON


BEGIN TRY
BEGIN TRANSACTION
    DECLARE @tmp_metadata AS TABLE(
        [namespace]      nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
        [namespace_ver]  nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
        [msg]            nvarchar(max) COLLATE Cyrillic_General_CI_AS NULL,
        [buffer_id]      bigint, 
        [session_id]     bigint, 
        [msg_id]         uniqueidentifier,
        [msg_key]        nvarchar(256) COLLATE Cyrillic_General_CI_AS NULL,
        [metaadapter_id] tinyint
    );


    WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.3/MDClasses','http://v8.1c.ru/8.3/xcf/readable' as xr)
    INSERT @tmp_metadata ([msg], [buffer_id], [session_id], [msg_id], [msg_key], [metaadapter_id], [namespace], [namespace_ver])
    SELECT  
        [msg], [buffer_id], [session_id], [msg_id], [msg_key], [metaadapter_id],
        [namespace] = CASE [metaadapter_id] WHEN  4
                            THEN JSON_VALUE([msg],'$."Реквизиты"[0]."ПространствоИменИсходное"') 
                        WHEN  1    THEN 'https://nevadwh.ru' + '/' + COALESCE(CAST(REPLACE(msg, 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Document/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)') ,
        CAST(REPLACE([msg], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/InformationRegister/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'), 
        CAST(REPLACE([msg], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Catalog/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)') 
    )
                        ELSE 'unknown'
                    END,
        [namespace_ver] = CASE [metaadapter_id] WHEN  4
                            THEN JSON_VALUE([msg],'$."Реквизиты"[0]."ПространствоИменСВерсией"')  
                        WHEN  1    THEN 'https://nevadwh.ru' + '/' +     COALESCE(CAST(REPLACE(msg, 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Document/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)') ,
        CAST(REPLACE([msg], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/InformationRegister/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'), 
        CAST(REPLACE([msg], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Catalog/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)') 
    ) +'/version' + '1'
                        ELSE 'unknown'
                    END
    FROM [metadata_buffer] WITH(XLOCK)
    WHERE [is_error] = 0;
    SET @RowCount = @@ROWCOUNT
    IF(@RowCount = 0)
        RETURN 0

    INSERT INTO metadata ([nkey], [namespace], [namespace_ver], [msg], [metaadapter_id])
    SELECT  
        CAST (SUBSTRING(HASHBYTES ( 'SHA2_256', COALESCE(p.[msg], '' ) ), 0,32) as uniqueidentifier) AS nkey, 
        [namespace], [namespace_ver], [msg], [metaadapter_id]
    FROM (
        SELECT * FROM @tmp_metadata
        WHERE [buffer_id] in (
            SELECT MAX([buffer_id]) FROM @tmp_metadata
            GROUP BY [namespace_ver]
            ) 
    ) p 
    WHERE NOT EXISTS (SELECT 1 FROM  metadata l WHERE l.[namespace_ver] = p.[namespace_ver])
    
    UPDATE m
        SET m.[msg] = p.[msg]
    FROM metadata m INNER JOIN
        (
            SELECT [namespace_ver], [msg] FROM @tmp_metadata
            WHERE [buffer_id] in (
                SELECT MAX(buffer_id) FROM @tmp_metadata
                GROUP BY [namespace_ver]
                ) 
        ) p ON m.[namespace_ver] = p.[namespace_ver]


    DELETE b FROM metadata_buffer b
        INNER JOIN @tmp_metadata t ON b.buffer_id = t.buffer_id
    
COMMIT TRANSACTION
END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()
    
    IF XACT_STATE() <> 0  AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END
    INSERT session_log ( [session_id], [session_state_id], [error_message], [dt_create])
    SELECT COALESCE(@session_id,(SELECT MAX([session_id]) as [session_id] FROM [session] )) as [session_id],
        4 as session_state_id,
        'Table metadata_buffer. Error: ' + @ErrorMessage as [error_message],
        GetDate() as dt_create
        
    IF NOT @ErrorMessage like '%deadlock%' 
        UPDATE b SET [is_error] = 1
        FROM metadata_buffer b
            INNER JOIN @tmp_metadata t ON b.buffer_id = t.buffer_id

    print @ErrorMessage
    RETURN -1
END CATCH
END