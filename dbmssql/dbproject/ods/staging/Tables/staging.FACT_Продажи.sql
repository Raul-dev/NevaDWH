CREATE TABLE [staging].[FACT_Продажи] (
    [id]         bigint IDENTITY(1,1) Primary key,
    [nkey]       uniqueidentifier NOT NULL,
    [FACT_Продажи.Товары] xml,
    [RefID] uniqueidentifier,
    [DeletionMark] bit,
    [Number] int,
    [Posted] bit,
    [Date] datetime2(0),
    [ДатаОтгрузки] datetime2(0),
    [Клиент] varchar(36),
    [ТипДоставки] varchar(500),
    [ПримерСоставногоТипа] varchar(36),
    [ПримерСоставногоТипа_ТипЗначения] varchar(128),
    [dt_update] datetime2(4)
);
GO
