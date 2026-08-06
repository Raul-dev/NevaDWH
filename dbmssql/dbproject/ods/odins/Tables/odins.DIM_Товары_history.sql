CREATE TABLE [odins].[DIM_Товары_history] (
  [NKey]            uniqueidentifier NOT NULL,
  [DwhSessionId]    bigint NULL,
  [RefID]  uniqueidentifier  NULL,
  [DeletionMark]  bit  NULL,
  [Code]  varchar(128)  NULL,
  [Description]  varchar(128)  NULL,
  [Описание]  varchar(255)  NULL,
  [CreatedAt]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Товары_history_CreatedAt] DEFAULT (getdate())
);
GO

