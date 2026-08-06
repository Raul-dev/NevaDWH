CREATE TABLE [odins].[FACT_Продажи.Товары_history] (
  [NKey]            uniqueidentifier NOT NULL,
  [DwhSessionId]    bigint NULL,
  [FACT_ПродажиRefID]  uniqueidentifier  NULL,
  [Доставка]  bit  NULL,
  [Товар]  varchar(36)  NULL,
  [Колличество]  decimal(12,0)  NULL,
  [Цена]  decimal(16,4)  NULL,
  [CreatedAt]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_FACT_Продажи.Товары_history_CreatedAt] DEFAULT (getdate())
);
GO

