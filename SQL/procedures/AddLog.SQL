USE [Recyclables_Test]
GO
/****** Object:  StoredProcedure [dbo].[AddLog]    Script Date: 31.01.2023 17:06:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author: Maxim Chernyakhovich>
-- Create date: <Create Date: 12.12.2022>
-- =============================================
ALTER PROCEDURE [dbo].[AddLog]

	@account nvarchar(450)
	,@sourse nvarchar(10)
	,@action nvarchar(255)
	,@type nvarchar(25)
	,@result nvarchar(255)
	
AS
BEGIN

declare @date as datetime = getdate()

insert into [Recyclables_Test].[dbo].[UserLogs] ([timestamp],[Account],[Sourse],[Action],[Type],[result])
values(@date, @account, @sourse, @action, @type, @result)

END
