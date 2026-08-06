CREATE TABLE [etl].[DwhSession] (
  [DwhSessionId]       bigint         identity(1,1) NOT NULL,
  [DataSourceId]       tinyint        NOT NULL,
  [DwhSessionStateId]  tinyint        NOT NULL,
  [CreateSession]      datetime2(4)   NULL,
  [ErrorMessage]       varchar(4000)  COLLATE Cyrillic_General_CI_AS NULL,
  [UpdatedAt]          datetime2(4)   CONSTRAINT [DF_etl_DwhSession_UpdatedAt] DEFAULT (sysdatetime()) NOT NULL,
  [CreatedAt]          datetime2(4)   CONSTRAINT [DF_etl_DwhSession_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_etl_DwhSession] PRIMARY KEY CLUSTERED ([DwhSessionId] ASC)
);
