CREATE TABLE [audit].[LogProcedures] (
    [LogID]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [MainID]           BIGINT         NULL,
    [ParentID]         BIGINT         NULL,
    [StartTime]        DATETIME       CONSTRAINT [DF_LogProcedures_start_datetime] DEFAULT (getdate()) NOT NULL,
    [EndTime]          DATETIME       NULL,
    [Duration]         INT            NULL,
    [RowCount]         INT            NULL,
    [SYS_USER_NAME]    VARCHAR (256)  CONSTRAINT [DF_LogProcedures_sys_user_name] DEFAULT (original_login()) NOT NULL,
    [SYS_HOST_NAME]    VARCHAR (100)  CONSTRAINT [DF_LogProcedures_sys_host_name] DEFAULT (host_name()) NOT NULL,
    [SYS_APP_NAME]     VARCHAR (128)  CONSTRAINT [DF_LogProcedures_sys_app_name] DEFAULT (app_name()) NOT NULL,
    [SPID]             INT            CONSTRAINT [DF_LogProcedures_spid] DEFAULT (@@spid) NOT NULL,
    [SPName]           VARCHAR (512)  NULL,
    [SPParams]         VARCHAR (MAX)  NULL,
    [SPInfo]           VARCHAR (MAX)  NULL,
    [ErrorMessage]     VARCHAR (2048) NULL,
    [TransactionCount] INT            NULL,
    CONSTRAINT [PK_audit_LogProcedures] PRIMARY KEY CLUSTERED ([LogID] ASC)
);

