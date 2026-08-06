CREATE TABLE [mq].[MetaData] (
  [NKey]              uniqueidentifier  NOT NULL,
  [Namespace]         nvarchar(256)     NOT NULL,
  [NamespaceVersion]  nvarchar(256)     NOT NULL,
  [MessageBody]       nvarchar(max)     NULL,
  [MetaAdapterId]     tinyint           NULL,
  [CreatedAt]         datetime2(2)      CONSTRAINT [DF_mq_MetaData_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_mq_MetaData] PRIMARY KEY CLUSTERED ([NKey] ASC)
);
