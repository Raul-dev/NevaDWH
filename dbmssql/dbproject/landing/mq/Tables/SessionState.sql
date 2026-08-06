CREATE TABLE [mq].[SessionState] (
  [SessionStateId]  tinyint       NOT NULL,
  [Name]            varchar(100)  NULL,
  CONSTRAINT [PK_mq_SessionState] PRIMARY KEY CLUSTERED ([SessionStateId] ASC)
);
