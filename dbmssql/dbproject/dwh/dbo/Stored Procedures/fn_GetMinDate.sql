﻿CREATE FUNCTION [dbo].[fn_GetMinDate]
(
) RETURNS datetime
WITH SCHEMABINDING, RETURNS NULL ON NULL INPUT
AS
BEGIN
    RETURN DATEFROMPARTS(1900, 01, 01) 
END