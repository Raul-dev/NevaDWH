CREATE PROCEDURE [odins].[load_FACT_Продажи_staging]
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256), @RowCount int
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[odins].[load_FACT_Продажи_staging]'
  SET @ProcedureParams =''

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

  MERGE INTO [odins].[FACT_Продажи] trg
  USING 
  (
    SELECT *
    FROM [staging].[FACT_Продажи] p
    ) src
    ON src.[NKey] = trg.[NKey] 
    WHEN MATCHED 
    THEN UPDATE SET
      [NKey] = src.[NKey],
      [RefID] = src.[RefID],
      [DeletionMark] = src.[DeletionMark],
      [Number] = src.[Number],
      [Posted] = src.[Posted],
      [Date] = src.[Date],
      [DateID] = src.[DateID],
      [ДатаОтгрузки] = src.[ДатаОтгрузки],
      [ДатаОтгрузкиID] = src.[ДатаОтгрузкиID],
      [Клиент] = src.[Клиент],
      [ТипДоставки] = src.[ТипДоставки],
      [ПримерСоставногоТипа] = src.[ПримерСоставногоТипа],
      [ПримерСоставногоТипа_ТипЗначения] = src.[ПримерСоставногоТипа_ТипЗначения],
      [UpdatedAt] = GetDate()
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      [NKey] ,
      [RefID],
      [DeletionMark],
      [Number],
      [Posted],
      [Date],
      [DateID],
      [ДатаОтгрузки],
      [ДатаОтгрузкиID],
      [Клиент],
      [ТипДоставки],
      [ПримерСоставногоТипа],
      [ПримерСоставногоТипа_ТипЗначения],
      [UpdatedAt]
  )
    VALUES
  (
      src.[NKey] ,
      src.[RefID],
      src.[DeletionMark],
      src.[Number],
      src.[Posted],
      src.[Date],
      src.[DateID],
      src.[ДатаОтгрузки],
      src.[ДатаОтгрузкиID],
      src.[Клиент],
      src.[ТипДоставки],
      src.[ПримерСоставногоТипа],
      src.[ПримерСоставногоТипа_ТипЗначения],
      src.[UpdatedAt]
  );


--Sub table
  DELETE FROM [odins].[FACT_Продажи.Товары];


  ;WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config')
  INSERT [odins].[FACT_Продажи.Товары] ([NKey], [FACT_ПродажиRefID], [Доставка], [Товар], [Колличество], [Цена],  [UpdatedAt])  SELECT   [NKey] = CAST(SUBSTRING(HASHBYTES('SHA2_256', COALESCE(CAST(b.RefID AS varchar(36)), '00000000-0000-0000-0000-000000000000')+ 
    '|' + COALESCE(CAST(STR(LTRIM(ROW_NUMBER() OVER (PARTITION BY b.RefID ORDER BY b.Id))) AS varchar(36)), '00000000-0000-0000-0000-000000000000' ) )
      , 0,16) as uniqueidentifier),
  [FACT_ПродажиRefID] = b.RefID,
  [Доставка] = X.C.value('(Доставка/text())[1]', 'bit'),
  [Товар] = X.C.value('(Товар/text())[1]', 'varchar(36)'),
  [Колличество] = X.C.value('(Колличество/text())[1]', 'decimal(12,0)'),
  [Цена] = X.C.value('(Цена/text())[1]', 'decimal(16,4)'),
  [UpdatedAt]
  FROM staging.[FACT_Продажи] b
  CROSS APPLY b.[FACT_Продажи.Товары].nodes('/Товары') AS X(C);
SET @RowCount = @@ROWCOUNT
EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
END

GO
