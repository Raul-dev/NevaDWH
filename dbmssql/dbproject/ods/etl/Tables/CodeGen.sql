CREATE TABLE [etl].[CodeGen] (
  [CodeGenId]          int            NOT NULL,
  [Namespace]          nvarchar(256)  COLLATE Cyrillic_General_CI_AS NOT NULL,
  [SchemaName]         nvarchar(128)  COLLATE Cyrillic_General_CI_AS NOT NULL,
  [TableName]          nvarchar(128)  COLLATE Cyrillic_General_CI_AS NOT NULL,
  [OdsEnableType]      smallint       NULL,
  [DwhEnableType]      smallint       NULL,
  [LandingEnableType]  smallint       NULL,
  CONSTRAINT [PK_etl_CodeGen] PRIMARY KEY CLUSTERED ([CodeGenId] ASC),
  CONSTRAINT [FK_etl_CodeGen_OdsEnableType] FOREIGN KEY ([OdsEnableType]) REFERENCES [etl].[CodeGenEnableType] ([CodeGenEnableTypeId])
);
