CREATE TABLE [staging].[DIM_Валюты] (
  [Id]         bigint IDENTITY(1,1) Primary key,
  [NKey]       uniqueidentifier NOT NULL,
  [DIM_Валюты.Представления] xml,
  [RefID] uniqueidentifier,
  [DeletionMark] bit,
  [Code] varchar(128),
  [Description] varchar(128),
  [ЗагружаетсяИзИнтернета] bit,
  [НаименованиеПолное] varchar(50),
  [Наценка] decimal(10,2),
  [ОсновнаяВалюта] varchar(36),
  [ПараметрыПрописи] varchar(200),
  [ФормулаРасчетаКурса] varchar(100),
  [СпособУстановкиКурса] varchar(500),
  [UpdatedAt] datetime2(4)
);
GO
