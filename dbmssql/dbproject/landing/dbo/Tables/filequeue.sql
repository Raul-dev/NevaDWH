CREATE TABLE [dbo].[filequeue] (
    [filequeue_id] BIGINT           IDENTITY (1, 1) NOT NULL,
    [session_id]   BIGINT              NOT NULL,
    [msg_key]      NVARCHAR (256)   NOT NULL,
    [msg_id]       UNIQUEIDENTIFIER NULL,
    [start_date]   DATETIME2 (4)    NULL,
    [finish_date]  DATETIME2 (4)    NULL,
    [filename]     VARCHAR (4000)   NULL,
    [filefolder]   VARCHAR (4000)   NULL,
    [filetype]     VARCHAR (4)      NULL,
    [error_msg]    VARCHAR (4000)   NULL,
    [state_id]     TINYINT          NOT NULL,
    [dt_create]    DATETIME2 (4)    CONSTRAINT [DF__filequeue__dt_create] DEFAULT (getdate()) NOT NULL,
    [dt_update]    DATETIME2 (4)    CONSTRAINT [DF__filequeue__dt_update] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_filequeue_id] PRIMARY KEY CLUSTERED ([msg_key] ASC, [filequeue_id] ASC) 
) 



