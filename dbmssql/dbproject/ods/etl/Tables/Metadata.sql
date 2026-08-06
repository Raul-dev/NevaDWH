CREATE TABLE [etl].[Metadata] (
    [NKey]             UNIQUEIDENTIFIER NOT NULL,
    [Namespace]        NVARCHAR (256)   NOT NULL,
    [NamespaceVersion] NVARCHAR (256)   NOT NULL,
    [MessageBody]      NVARCHAR (MAX)   NULL,
    [MetaAdapterId]    TINYINT          NULL,
    [CreatedAt]        DATETIME2 (2)    CONSTRAINT [DF_etl_Metadata_CreatedAt] DEFAULT (SYSDATETIME()) NOT NULL,
    CONSTRAINT [PK_etl_Metadata] PRIMARY KEY CLUSTERED ([NKey] ASC)
);
