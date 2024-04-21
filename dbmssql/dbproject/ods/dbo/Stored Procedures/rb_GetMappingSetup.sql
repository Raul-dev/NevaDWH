CREATE   PROCEDURE [dbo].[rb_GetMappingSetup]
AS

SELECT 
	metamap_id,
	msg_key,
	table_name,
	metaadapter_id,
	etl_query
FROM [metamap] WHERE is_enable = 1
return
--DROP TABLE #TempROUTE
SELECT 
	metamap_id,
	msg_key,
	table_name,
	metaadapter_id,
	etl_query,
	MaxID = CAST(NULL AS INT) 
	
	INTO #TempROUTE
FROM [metamap] WHERE is_enable = 1

DECLARE @SqlExec NVARCHAR(MAX), @metamap_id INT
SET @metamap_id = 1

WHILE NOT @metamap_id IS NULL
BEGIN
	SELECT @SqlExec = N'
		UPDATE #TempROUTE SET MaxID = ISNULL((SELECT count(*) FROM '+table_name+'), 0 ) + 1
		WHERE table_name = N'''+TABLE_NAME+'''
		'
	FROM #TempROUTE
	WHERE metamap_id = @metamap_id
	print @SqlExec
	EXEC (@SqlExec)
	SELECT @metamap_id = (SELECT TOP 1 metamap_id FROM #TempROUTE WHERE metamap_id > @metamap_id ORDER BY metamap_id ASC)
	print @metamap_id
END
SELECT * FROM #TempROUTE 
ORDER BY metamap_id ASC