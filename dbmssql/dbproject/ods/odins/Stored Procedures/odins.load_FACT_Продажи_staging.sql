CREATE PROCEDURE [odins].[load_FACT_Продажи_staging]
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
    SET @ProcedureParams =''

    EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

    MERGE INTO [odins].[FACT_Продажи] trg
    USING 
    (
        SELECT *
        FROM [staging].[FACT_Продажи] p
         ) src
        ON src.[nkey] = trg.[nkey] 
         WHEN MATCHED 
        THEN UPDATE SET
            [nkey] = src.[nkey],
            [RefID] = src.[RefID],
            [DeletionMark] = src.[DeletionMark],
            [Number] = src.[Number],
            [Posted] = src.[Posted],
            [Date] = src.[Date],
            [ДатаОтгрузки] = src.[ДатаОтгрузки],
            [Клиент] = src.[Клиент],
            [ТипДоставки] = src.[ТипДоставки],
            [ПримерСоставногоТипа] = src.[ПримерСоставногоТипа],
            [ПримерСоставногоТипа_ТипЗначения] = src.[ПримерСоставногоТипа_ТипЗначения],
            [dt_update] = GetDate()
        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            [nkey] ,
            [RefID],
            [DeletionMark],
            [Number],
            [Posted],
            [Date],
            [ДатаОтгрузки],
            [Клиент],
            [ТипДоставки],
            [ПримерСоставногоТипа],
            [ПримерСоставногоТипа_ТипЗначения],
            [dt_update]
    )
        VALUES
    (
            src.[nkey] ,
            src.[RefID],
            src.[DeletionMark],
            src.[Number],
            src.[Posted],
            src.[Date],
            src.[ДатаОтгрузки],
            src.[Клиент],
            src.[ТипДоставки],
            src.[ПримерСоставногоТипа],
            src.[ПримерСоставногоТипа_ТипЗначения],
            [dt_update]
     );


--Sub table
    DELETE FROM [odins].[FACT_Продажи.Товары];


    WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config')
    INSERT [odins].[FACT_Продажи.Товары] (nkey, FACT_ПродажиRefID, Доставка, Товар, Колличество, Цена,  dt_update)    SELECT     [nkey] = CAST(SUBSTRING(HASHBYTES('SHA2_256', COALESCE(CAST(b.RefID AS varchar(36)), '00000000-0000-0000-0000-000000000000')+ 
        '|' + COALESCE(CAST(STR(LTRIM(ROW_NUMBER() OVER (PARTITION BY b.RefID ORDER BY b.id))) AS varchar(36)), '00000000-0000-0000-0000-000000000000' ) )
            , 0,16) as uniqueidentifier),
    [FACT_ПродажиRefID] = b.RefID,
    [Доставка] = X.C.value('(Доставка/text())[1]', 'bit'),
    [Товар] = X.C.value('(Товар/text())[1]', 'varchar(36)'),
    [Колличество] = X.C.value('(Колличество/text())[1]', 'decimal(12,0)'),
    [Цена] = X.C.value('(Цена/text())[1]', 'decimal(16,4)'),
    [dt_update]
    FROM staging.[FACT_Продажи] b
    CROSS APPLY b.[FACT_Продажи.Товары].nodes('/Товары') AS X(C);
SET @RowCount = @@ROWCOUNT
EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount
END

GO
