CREATE TABLE [staging].[DIM_Клиенты] (
  [Id]         bigint IDENTITY(1,1) Primary key,
  [NKey]       uniqueidentifier NOT NULL,
  [RefID] uniqueidentifier,
  [DeletionMark] bit,
  [Code] varchar(128),
  [Description] varchar(128),
  [Контакт] varchar(500),
  [UpdatedAt] datetime2(4)
);
GO
