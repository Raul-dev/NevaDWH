CREATE TABLE [etl].[DwhSessionState] (
  [DwhSessionStateId]  tinyint       NOT NULL,
  [Name]               varchar(100)  NULL,
  CONSTRAINT [PK_etl_DwhSessionState] PRIMARY KEY CLUSTERED ([DwhSessionStateId] ASC)
);
