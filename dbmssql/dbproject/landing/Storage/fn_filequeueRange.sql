CREATE PARTITION FUNCTION [fn_filequeueRange](nvarchar(256))
  AS RANGE RIGHT
  FOR VALUES (N'Документы.', N'Документы.Продажи', N'Справочники.');
