CREATE TABLE [dbo].[metadata_buffer] (
    [buffer_id]      bigint        IDENTITY (1, 1) NOT NULL,
    [session_id]     bigint        NOT NULL,
    [msg_id]         varchar (36)  NOT NULL,
    [msg]            varchar (MAX) NULL,
    [msg_key]        varchar (256) NULL,
    [metaadapter_id] tinyint       NULL,
    [is_error]       bit           CONSTRAINT [DF_metadata_buffer_is_error_DEFAULT] DEFAULT ((0)) NOT NULL,
    [dt_create]      datetime2(4)  CONSTRAINT [DF_metadata_buffer_dt_update_DEFAULT] DEFAULT (getdate()) NOT NULL,
    [dt_update]      datetime2(4)  NOT NULL CONSTRAINT DF_dbo_metadata_buffer_dt_update_DEFAULT DEFAULT (DATEFROMPARTS(1900, 01, 01))

    CONSTRAINT [PK_metadata_buffer] PRIMARY KEY CLUSTERED 
    (
	    [buffer_id] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
);



