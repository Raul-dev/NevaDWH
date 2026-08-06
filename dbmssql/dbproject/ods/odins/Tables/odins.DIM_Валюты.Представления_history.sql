CREATE TABLE [odins].[DIM_Валюты.Представления_history] (
  [NKey]            uniqueidentifier NOT NULL,
  [DwhSessionId]    bigint NULL,
  [DIM_ВалютыRefID]  uniqueidentifier  NULL,
  [КодЯзыка]  varchar(10)  NULL,
  [ПараметрыПрописи]  varchar(200)  NULL,
  [CreatedAt]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Валюты.Представления_history_CreatedAt] DEFAULT (getdate())
);
GO

