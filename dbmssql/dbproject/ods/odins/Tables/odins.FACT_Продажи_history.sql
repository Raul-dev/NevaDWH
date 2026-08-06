CREATE TABLE [odins].[FACT_Продажи_history] (
  [NKey]            uniqueidentifier NOT NULL,
  [DwhSessionId]    bigint NULL,
  [RefID]  uniqueidentifier  NULL,
  [DeletionMark]  bit  NULL,
  [Number]  int  NULL,
  [Posted]  bit  NULL,
  [Date]  datetime2(0)  NULL,
  [DateID]  int  NULL,
  [ДатаОтгрузки]  datetime2(0)  NULL,
  [ДатаОтгрузкиID]  int  NULL,
  [Клиент]  varchar(36)  NULL,
  [ТипДоставки]  varchar(500)  NULL,
  [ПримерСоставногоТипа]  varchar(36)  NULL,
  [ПримерСоставногоТипа_ТипЗначения]  varchar(128)  NULL,
  [CreatedAt]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_FACT_Продажи_history_CreatedAt] DEFAULT (getdate())
);
GO

