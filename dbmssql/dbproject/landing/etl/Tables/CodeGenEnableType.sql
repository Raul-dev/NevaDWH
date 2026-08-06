CREATE TABLE [etl].[CodeGenEnableType] (
  [CodeGenEnableTypeId]  smallint       NOT NULL,
  [Description]          nvarchar(256)  COLLATE Cyrillic_General_CI_AS NOT NULL,
  CONSTRAINT [PK_etl_CodeGenEnableType] PRIMARY KEY CLUSTERED ([CodeGenEnableTypeId] ASC)
);
