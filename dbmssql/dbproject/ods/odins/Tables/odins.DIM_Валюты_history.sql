CREATE TABLE [odins].[DIM_Валюты_history] (
    [nkey]            uniqueidentifier NOT NULL,
    [dwh_session_id]  bigint NULL,
    [RefID]  uniqueidentifier  NULL,
    [DeletionMark]  bit  NULL,
    [Code]  varchar(128)  NULL,
    [Description]  varchar(128)  NULL,
    [ЗагружаетсяИзИнтернета]  bit  NULL,
    [НаименованиеПолное]  varchar(50)  NULL,
    [Наценка]  decimal(10,2)  NULL,
    [ОсновнаяВалюта]  varchar(36)  NULL,
    [ПараметрыПрописи]  varchar(200)  NULL,
    [ФормулаРасчетаКурса]  varchar(100)  NULL,
    [СпособУстановкиКурса]  varchar(500)  NULL,
    [dt_create]   datetime2(4)   NOT NULL CONSTRAINT [DF_odins_DIM_Валюты_history_dt_create_DEFAULT] DEFAULT (getdate())
);
GO

