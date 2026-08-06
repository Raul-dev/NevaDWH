CREATE TABLE [etl].[DwhProcessingDetails] (
  [ProcessingId]  bigint        identity(1,1) NOT NULL,
  [DwhSessionId]  bigint        NULL,
  [SchemaName]    varchar(128)  NULL,
  [TableName]     varchar(128)  NULL,
  [RowCount]      bigint        NULL,
  CONSTRAINT [PK_etl_DwhProcessingDetails] PRIMARY KEY CLUSTERED ([ProcessingId] ASC),
  CONSTRAINT [FK_etl_DwhProcessingDetails_DwhSession] FOREIGN KEY ([DwhSessionId]) REFERENCES [etl].[DwhSession] ([DwhSessionId])
);
