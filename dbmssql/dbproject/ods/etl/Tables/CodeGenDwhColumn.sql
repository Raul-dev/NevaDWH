CREATE TABLE [etl].[CodeGenDwhColumn] (
  [CodeGenDwhColumnId]  int           NOT NULL,
  [CodeGenDwhTableId]   int           NOT NULL,
  [ColumnName]          varchar(128)  NOT NULL,
  [DataType]            varchar(128)  NOT NULL,
  [TextLength]          int           NULL,
  [Precision]           int           NULL,
  [Scale]               int           NULL,
  [IsEnabled]            bit           CONSTRAINT [DF_etl_CodeGenDwhColumn_IsEnabled] DEFAULT ((1)) NOT NULL,
  [IsVersionkey]        bit           CONSTRAINT [DF_etl_CodeGenDwhColumn_IsVersionkey] DEFAULT ((0)) NOT NULL,
  [IsNulable]           bit           CONSTRAINT [DF_etl_CodeGenDwhColumn_IsNulable] DEFAULT ((1)) NOT NULL,
  [NullValue]           varchar(128)  NULL,
  CONSTRAINT [PK_etl_CodeGenDwhColumn] PRIMARY KEY CLUSTERED ([CodeGenDwhColumnId] ASC),
  CONSTRAINT [FK_etl_CodeGenDwhColumn_CodeGenDwhTable] FOREIGN KEY ([CodeGenDwhTableId]) REFERENCES [etl].[CodeGenDwhTable] ([CodeGenDwhTableId])
);
