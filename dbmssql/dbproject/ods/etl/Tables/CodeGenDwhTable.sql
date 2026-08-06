CREATE TABLE [etl].[CodeGenDwhTable] (
  [CodeGenDwhTableId]  int           NOT NULL,
  [CodeGenId]          int           NOT NULL,
  [TableName]          varchar(128)  COLLATE Cyrillic_General_CI_AS NOT NULL,
  [IsRoot]             bit           NOT NULL,
  [IsEnable]           bit           NOT NULL,
  [DwhTableName]       varchar(128)  COLLATE Cyrillic_General_CI_AS NOT NULL,
  [IsVkeySession]      bit           CONSTRAINT [DF_etl_CodeGenDwhTable_IsVkeySession] DEFAULT ((0)) NOT NULL,
  [IsVkeySourcename]   bit           CONSTRAINT [DF_etl_CodeGenDwhTable_IsVkeySourcename] DEFAULT ((0)) NOT NULL,
  [IsHistorical]       bit           CONSTRAINT [DF_etl_CodeGenDwhTable_IsHistorical] DEFAULT ((0)) NOT NULL,
  CONSTRAINT [PK_etl_CodeGenDwhTable] PRIMARY KEY CLUSTERED ([CodeGenDwhTableId] ASC),
  CONSTRAINT [FK_etl_CodeGenDwhTable_CodeGen] FOREIGN KEY ([CodeGenId]) REFERENCES [etl].[CodeGen] ([CodeGenId])
);
