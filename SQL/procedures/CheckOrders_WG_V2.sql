USE [Recyclables_Prod]
GO
/****** Object:  StoredProcedure [dbo].[CheckOrders_WG_V2]    Script Date: 21.02.2023 15:51:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author: Maxim Chernyakhovich>
-- Create date: <Create Date: 12.12.2022>
-- =============================================
ALTER PROCEDURE [dbo].[CheckOrders_WG_V2]
	@branch varchar(100)
	,@date1 datetime
	,@date2 datetime
	,@status varchar(50)
	,@OSP varchar(200)
	
AS
BEGIN

declare @region varchar(100) = (select Distinct region from monitoring.dbo.vpostsprav where branch like @branch)

declare @check_status varchar(50) = 
case
	when @status = 'Все' then '%'
	else @status
end

;with basic_data_postcodes as (

SELECT 
	format(Os.DateStatusCreation, 'dd.MM.yyyy HH:mm') as DateStatusCreation
	,OS.orderid
	,OS.Account
	,O.OrderNumber
	,O.OSP 
	,MainPostOffice
	,s.name  as Status
	,concat(replace(TC.Name, '.', ','), ' ', TC.Measure) as TypeName
	,OC.Amount
	,isnull(OC.ChangedAmount, 0) as ChangedAmount
	,Comment
	FROM [Recyclables_Prod].[dbo].[Orders] O
		left join [Recyclables_Prod].[dbo].[OrderContents] OC on O.Id = OC.OrderId
		left join [Recyclables_Prod].[dbo].[OrderStatus] OS on OS.OrderId = O.Id and OS.OSP = O.OSP
		left join [Recyclables_Prod].[dbo].[Status] S on S.Id = OS.StatusId
		left join [Recyclables_Prod].[dbo].[TypeContents] TC on OC.TypeContentsId = TC.Id
		join Monitoring.dbo.vPostSprav VPS on o.OSP = VPS.Postcode and O.osp like '______' and O.osp like '%[0-9]%' and VPS.Branch = @branch
	where O.OrderTypeId = 1
	and Os.DateStatusCreation between @date1 and  dateadd(day,1,@date2)

), basic_data_users as (

	SELECT 
	format(Os.DateStatusCreation, 'dd.MM.yyyy HH:mm') as DateStatusCreation
	,OS.orderid
	,OS.Account
	,O.OrderNumber
	,O.OSP 
	,'Почтамт не известен' As MainPostOffice
	,s.name  as Status
	,concat(replace(TC.Name, '.', ','), ' ', TC.Measure) as TypeName
	,OC.Amount
	,isnull(OC.ChangedAmount, 0) as ChangedAmount
	,Comment
	FROM [Recyclables_Prod].[dbo].[Orders] O
		left join [Recyclables_Prod].[dbo].[OrderContents] OC on O.Id = OC.OrderId
		left join [Recyclables_Prod].[dbo].[OrderStatus] OS on OS.OrderId = O.Id and OS.OSP = O.OSP
		left join [Recyclables_Prod].[dbo].[Status] S on S.Id = OS.StatusId
		left join [Recyclables_Prod].[dbo].[TypeContents] TC on OC.TypeContentsId = TC.Id
	where O.OrderTypeId = 1
	and Os.DateStatusCreation between @date1 and  dateadd(day,1,@date2)
	and O.osp not like '______' 
	and O.osp not like '%[0-9]%'
	and O.Region is not null
	and O.Region != ''
	and @region = O.Region

), basic_data_union as (

	select * from basic_data_users
	union all
	select * from basic_data_postcodes

),

last_status as (

	select 
		format(OS.DateStatusCreation, 'dd.MM.yyyy HH:mm') as DateLastStatusCreation
		,OS.orderid
		,OS.StatusId as las_id
		,s.name  as Status
		,OS.Comment as Comment
	from orders o
	join [OrderStatus] os on o.id = os.orderid
	join Status S on s.Id = OS.StatusId
	where O.OrderTypeId = 1 and StatusId != 1
	
)

select 
MainPostOffice
,count(bd.OrderNumber)/22 as Amount
,sum(ChangedAmount) as ChangedAmount
from basic_data_union as bd
left join last_status ls on bd.orderid = ls.orderid
where 
isnull(ls.status, 'Создана') like @check_status
and bd.OSP like '%' + @OSP + '%'
group by MainPostOffice

END