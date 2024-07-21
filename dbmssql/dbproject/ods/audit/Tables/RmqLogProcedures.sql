CREATE TABLE [audit].[RmqLogProcedures](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[MainID] [bigint] NULL,
	[ParentID] [bigint] NULL,
	[StartTime] datetime2(4)         NOT NULL,
	[EndTime] datetime2(4) NULL,
	[Duration] [int] NULL,
	[RowCount] [int] NULL,
	[SysUserName] [varchar](256)  NOT NULL,
	[SysHostName] [varchar](100)  NOT NULL,
	[SysDbName]   [varchar](128)  NOT NULL,
	[SysAppName] [varchar](128)   NOT NULL,
	[SPID] [int]                    NOT NULL,
	[ProcedureName] [varchar](512) NULL,
	[ProcedureParams] [varchar](max) NULL,
	[ProcedureInfo] [varchar](max) NULL,
	[ErrorMessage] [varchar](2048) NULL,
	[TransactionCount] [int] NULL,
 CONSTRAINT [PK_audit_RmqLogProcedures] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

