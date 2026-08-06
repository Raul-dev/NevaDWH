CREATE TABLE [odins].[DIM_Клиенты_history] (
  [NKey]            uniqueidentifier NOT NULL,
  [DwhSessionId]    bigint NULL,
  [RefID]  uniqueidentifier  NULL,
  [DeletionMark]  bit  NULL,
  [Code]  varchar(128)  NULL,
  [Description]  varchar(128)  NULL,
  [Контакт]  varchar(500)  NULL,
  [CreatedAt]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Клиенты_history_CreatedAt] DEFAULT (getdate())
);
GO

