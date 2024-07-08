CREATE TABLE [odins].[FACT_Продажи_buffer] (
    [buffer_id]   bigint IDENTITY(1,1) Primary key,
    [session_id]  bigint         NOT NULL,
    [msg_id]      uniqueidentifier   NOT NULL,
    [msg]         xml            NULL,
    [is_error]    bit            NOT NULL CONSTRAINT DF_odins_FACT_Продажи_buffer_IS_ERROR_DEFAULT DEFAULT 0,
    [msgtype_id]  tinyint        CONSTRAINT [DF_odins_FACT_Продажи_buffer_msgtype_id] DEFAULT ((1)) NOT NULL,
    [dt_create]   datetime2(4)   NOT NULL CONSTRAINT DF_odins_FACT_Продажи_buffer_dt_create_DEFAULT DEFAULT (GetDate()),
    [dt_update]   datetime2(4)   NOT NULL CONSTRAINT DF_odins_FACT_Продажи_buffer_dt_update_DEFAULT DEFAULT (DATEFROMPARTS(1900, 01, 01))
    ,[RefID]      AS ([dbo].[fn_GetRef]([msg],'DocumentObject.Продажи')),
);
GO
CREATE NONCLUSTERED INDEX [idx_FACT_Продажи_buffer] ON [odins].[FACT_Продажи_buffer]
(
    [is_error] ASC,
    [RefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
ON [PRIMARY]

GO
