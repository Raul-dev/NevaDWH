CREATE TABLE [staging].[DIM_Товары] (
  [Id]         bigint IDENTITY(1,1) Primary key,
  [NKey]       uniqueidentifier NOT NULL,
  [RefID] uniqueidentifier,
  [DeletionMark] bit,
  [Code] varchar(128),
  [Description] varchar(128),
  [Описание] varchar(255),
  [UpdatedAt] datetime2(4)
);
GO
