CREATE TABLE [target].[DIM_Товары] (
    [id]                bigint NOT NULL,
    [session_id]        bigint NOT NULL,
    [source_name]       varchar(128) COLLATE Cyrillic_General_CI_AS NULL,
    [nkey]              uniqueidentifier NOT NULL,
    [vkey]              uniqueidentifier NOT NULL,
    [start_date]        datetime NOT NULL,
    [end_date]          datetime NOT NULL,
    [RefID]  uniqueidentifier  NOT NULL ,
    [DeletionMark]  bit  NULL ,
    [Code]  varchar(128)  NULL ,
    [Description]  varchar(128)  NULL ,
    [Описание]  varchar(255)  NULL ,
    [session_id_update] bigint NOT NULL,
    [dt_update]         datetime2(4) NOT NULL CONSTRAINT [DF_DIM_Товары_target_dt_update_DEFAULT] DEFAULT (getdate()),
    [dt_create]         datetime2(4) NOT NULL CONSTRAINT [DF_DIM_Товары_target_dt_create_DEFAULT] DEFAULT (getdate())
);
GO
