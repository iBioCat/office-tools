USE [Recyclables_Prod]
GO
/****** Object:  StoredProcedure [dbo].[CheckOrders]    Script Date: 17.02.2023 11:33:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author: Maxim Chernyakhovich>
-- Create date: <Create Date: 12.12.2022>
-- =============================================
ALTER PROCEDURE [dbo].[CheckOrders]
	@status nvarchar(100)
	,@account nvarchar(45)
	,@OSP varchar(100)
	,@from varchar(10)
	,@to varchar(10)
	
AS
BEGIN

declare @date_from as varchar(10) = format(cast(iif(@from = '', '2022-11-01', @from) as date),'yyyy-MM-dd')
declare @date_to as varchar(10) = format(cast(iif(@to = '', cast(getdate()+1 as date), cast(@to as datetime)+1) as date),'yyyy-MM-dd')

declare @account_region int = (
SELECT iif(region='',iif(r.Description = 'Администратор', 78, region),region) as region from [NetworkServicesWebPortal].[dbo].[users] u left join [NetworkServicesWebPortal].[dbo].[UsersRoles] ur on u.id = ur.userid left join [NetworkServicesWebPortal].[dbo].[Roles] r on ur.RoleId = r.id where u.username = @account)

declare @status_1 varchar(100) = case when @status = '' then '%' 
								  else @status
							 end
declare @ProcedureName nvarchar(25) = 'CheckOrders'

BEGIN TRY
;with basic_data as (

SELECT 
	format(Os.DateStatusCreation, 'dd.MM.yyyy HH:mm') as DateStatusCreation
	,OS.orderid
	,O.OrderNumber
	,OS.Account
	,O.OSP
	,s.name  as Status
	,concat(replace(TC.Name, '.', ','), ' ', TC.Measure) as TypeName
	,OC.Amount
	,isnull(OC.ChangedAmount, 0) as ChangedAmount
	,region
	FROM [Recyclables_Prod].[dbo].[Orders] O
		left join [Recyclables_Prod].[dbo].[OrderContents] OC on O.Id = OC.OrderId
		left join [Recyclables_Prod].[dbo].[OrderStatus] OS on OS.OrderId = O.Id and OS.OSP = O.OSP
		left join [Recyclables_Prod].[dbo].[Status] S on S.Id = OS.StatusId
		left join [Recyclables_Prod].[dbo].[TypeContents] TC on OC.TypeContentsId = TC.Id
	where O.OrderTypeId = 1
	and StatusId = 1
	and DateStatusCreation between  @date_from and @date_to
)

, last_status as (
	select 
		format(OS.DateStatusCreation, 'dd.MM.yyyy HH:mm') as DateLastStatusCreation
		,OS.orderid
		,OS.Account as Executor
		,OS.OSP as ExecutorOSP
		,OS.StatusId as las_id
		,s.name  as Status
		,OS.Comment as Comment
	from orders o
	join [OrderStatus] os on o.id = os.orderid
	join Status S on s.Id = OS.StatusId
	where O.OrderTypeId = 1 and StatusId != 1
	
)

select 
DateStatusCreation
,iif(DateLastStatusCreation is null, DateStatusCreation, DateLastStatusCreation) as DateLastStatusCreation
,OrderNumber
,bd.Account
,bd.osp
,iif(ls.Status is null, 'Создана', ls.Status) as Status
,TypeName
,Amount
,ChangedAmount
,isnull(ls.Comment, '') as Comment
,Executor
,iif(OSP = ExecutorOSP, NULL, ExecutorOSP) as ExecutorOSP
,bd.OrderId
from basic_data as bd
left join last_status ls on bd.orderid = ls.orderid
where 
iif(ls.Status is null, 'Создана', ls.Status) like @status_1
and bd.OSP like @OSP + '%'
and bd.Region = @account_region
order by OrderNumber desc, DateStatusCreation, bd.osp

declare @info_message varchar(1100) = ('Ok. Status: ' + @status + '. Account: ' + @account + '. OSP: ' + @OSP + '. from: ' + @from + '. to: ' + @to)
exec addlog @account, 'SQL',@ProcedureName, 'INFO' , @info_message

END TRY
BEGIN CATCH
declare @err_num varchar(50) = (select ERROR_NUMBER() AS ErrorNumber)
declare @err_mes varchar(50) = (select ERROR_MESSAGE() AS ErrorMessage)
declare @message varchar(1100) = (select 'NUMBER: ' + @err_num + ' MESSAGE: ' + @err_mes)

exec addlog @account, 'SQL',@ProcedureName, 'ERROR' ,@message
END CATCH

END
