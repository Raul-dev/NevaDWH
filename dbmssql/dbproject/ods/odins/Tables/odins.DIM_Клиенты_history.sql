CREATE TABLE [odins].[DIM_Клиенты_history] (
    [nkey]            uniqueidentifier NOT NULL,
    [dwh_session_id]  bigint NULL,
    [RefID]  uniqueidentifier  NULL,
    [DeletionMark]  bit  NULL,
    [Code]  varchar(128)  NULL,
    [Description]  varchar(128)  NULL,
    [Контакт]  varchar(500)  NULL,
    [dt_create]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Клиенты_history_dt_create_DEFAULT] DEFAULT (getdate())
);
GO

