CREATE TABLE [staging].[FACT_Продажи] (
  [Id]         bigint IDENTITY(1,1) Primary key,
  [NKey]       uniqueidentifier NOT NULL,
  [FACT_Продажи.Товары] xml,
  [RefID] uniqueidentifier,
  [DeletionMark] bit,
  [Number] int,
  [Posted] bit,
  [Date] datetime2(0),
  [DateID] int,
  [ДатаОтгрузки] datetime2(0),
  [ДатаОтгрузкиID] int,
  [Клиент] varchar(36),
  [ТипДоставки] varchar(500),
  [ПримерСоставногоТипа] varchar(36),
  [ПримерСоставногоТипа_ТипЗначения] varchar(128),
  [UpdatedAt] datetime2(4)
);
GO
