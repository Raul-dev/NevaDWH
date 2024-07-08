CREATE TABLE [dbo].[dwh_session] (
    [dwh_session_id]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [data_source_id]       TINYINT         NOT NULL,
    [dwh_session_state_id] TINYINT         NOT NULL,
    [create_session]       DATETIME2 (4)   NULL,
    [error_message]        VARCHAR (4000)  COLLATE Cyrillic_General_CI_AS NULL,
    [dt_update]            DATETIME2 (4)   CONSTRAINT [DF_dwh_session_dt_update_DEFAULT] DEFAULT (getdate()) NOT NULL,
    [dt_create]            DATETIME2 (4)   CONSTRAINT [DF_dwh_session_dt_create_DEFAULT] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_dwh_session] PRIMARY KEY CLUSTERED ([dwh_session_id] ASC)
);

