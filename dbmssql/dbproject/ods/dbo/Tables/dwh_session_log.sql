CREATE TABLE [dbo].[dwh_session_log] (
    [dwh_session_log_id]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [dwh_session_id]       BIGINT         NOT NULL,
    [dwh_session_state_id] TINYINT        NOT NULL,
    [error_message]        VARCHAR (4000) NULL,
    [dt_create]            DATETIME2 (4)  CONSTRAINT [DF_dwh_session_log_date_DEFAULT] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_dwh_session_log] PRIMARY KEY CLUSTERED ([dwh_session_log_id] ASC),
    CONSTRAINT [FK_dwh_session_log_dwh_session] FOREIGN KEY ([dwh_session_id]) REFERENCES [dbo].[dwh_session] ([dwh_session_id]),
    CONSTRAINT [FK_dwh_session_log_dwh_session_state] FOREIGN KEY ([dwh_session_state_id]) REFERENCES [dbo].[dwh_session_state] ([dwh_session_state_id])
);

