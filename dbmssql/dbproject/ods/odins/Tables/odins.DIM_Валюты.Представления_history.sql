CREATE TABLE [odins].[DIM_Валюты.Представления_history] (
    [nkey]              uniqueidentifier NOT NULL,
    [dwh_session_id]           bigint NULL,
    [DIM_ВалютыRefID]            uniqueidentifier  NULL,
    [КодЯзыка]            varchar(10)  NULL,
    [ПараметрыПрописи]            varchar(200)  NULL,
    [dt_create]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Валюты.Представления_history_dt_create_DEFAULT] DEFAULT (getdate())
);
GO

