CREATE TABLE [etl].[FileQueue] (
    [FileQueueId]  BIGINT           IDENTITY (1, 1) NOT NULL,
    [SessionId]    BIGINT           NOT NULL,
    [MessageKey]   NVARCHAR (256)   NOT NULL,
    [MessageId]    UNIQUEIDENTIFIER NULL,
    [StartDate]    DATETIME2 (4)    NULL,
    [FinishDate]   DATETIME2 (4)    NULL,
    [FileName]     VARCHAR (4000)   NULL,
    [FileFolder]   VARCHAR (4000)   NULL,
    [FileType]     VARCHAR (4)      NULL,
    [ErrorMessage] VARCHAR (4000)   NULL,
    [StateId]      TINYINT          NOT NULL,
    [CreatedAt]    DATETIME2 (4)    CONSTRAINT [DF_etl_FileQueue_CreatedAt] DEFAULT (SYSDATETIME()) NOT NULL,
    [UpdatedAt]    DATETIME2 (4)    CONSTRAINT [DF_etl_FileQueue_UpdatedAt] DEFAULT (SYSDATETIME()) NOT NULL,
    CONSTRAINT [PK_etl_FileQueue] PRIMARY KEY CLUSTERED ([MessageKey] ASC, [FileQueueId] ASC) ON [filequeueRange] ([MessageKey])
) ON [filequeueRange] ([MessageKey]);
