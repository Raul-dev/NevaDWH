CREATE TABLE [dbo].[dwh_session_state] (
    [dwh_session_state_id] TINYINT       NOT NULL,
    [name]                 VARCHAR (100) NULL,
    CONSTRAINT [PK_dwh_session_state] PRIMARY KEY CLUSTERED ([dwh_session_state_id] ASC)
);

