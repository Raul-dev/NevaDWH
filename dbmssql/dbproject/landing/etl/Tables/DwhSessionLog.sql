CREATE TABLE [etl].[DwhSessionLog] (
  [DwhSessionLogId]    bigint         identity(1,1) NOT NULL,
  [DwhSessionId]       bigint         NOT NULL,
  [DwhSessionStateId]  tinyint        NOT NULL,
  [ErrorMessage]       varchar(4000)  NULL,
  [CreatedAt]          datetime2(4)   CONSTRAINT [DF_etl_DwhSessionLog_CreatedAt] DEFAULT (sysdatetime()) NOT NULL,
  CONSTRAINT [PK_etl_DwhSessionLog] PRIMARY KEY CLUSTERED ([DwhSessionLogId] ASC),
  CONSTRAINT [FK_etl_DwhSessionLog_DwhSession] FOREIGN KEY ([DwhSessionId]) REFERENCES [etl].[DwhSession] ([DwhSessionId]),
  CONSTRAINT [FK_etl_DwhSessionLog_DwhSessionState] FOREIGN KEY ([DwhSessionStateId]) REFERENCES [etl].[DwhSessionState] ([DwhSessionStateId])
);
