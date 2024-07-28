CREATE TABLE [odins].[DIM_Товары_history] (
    [nkey]            uniqueidentifier NOT NULL,
    [dwh_session_id]  bigint NULL,
    [RefID]  uniqueidentifier  NULL,
    [DeletionMark]  bit  NULL,
    [Code]  varchar(128)  NULL,
    [Description]  varchar(128)  NULL,
    [Описание]  varchar(255)  NULL,
    [dt_create]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Товары_history_dt_create_DEFAULT] DEFAULT (getdate())
);
GO

