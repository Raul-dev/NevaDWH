CREATE TABLE [mq].[MetaMap] (
  [MetaMapId]         smallint       NOT NULL,
  [MessageKey]        nvarchar(256)  NOT NULL,
  [TableName]         nvarchar(128)  NOT NULL,
  [MetaAdapterId]     tinyint        NULL,
  [Namespace]         nvarchar(256)  NULL,
  [NamespaceVersion]  nvarchar(256)  NULL,
  [EtlProcedure]      nvarchar(256)  NULL,
  [ImportQuery]       nvarchar(256)  NULL,
  [IsEnabled]         bit            NOT NULL,
  CONSTRAINT [PK_mq_MetaMap] PRIMARY KEY CLUSTERED ([MetaMapId] ASC)
);
