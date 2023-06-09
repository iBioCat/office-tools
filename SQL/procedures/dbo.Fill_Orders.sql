USE [Recyclables_Prod]
GO
/****** Object:  StoredProcedure [dbo].[Fill_Orders]    Script Date: 17.02.2023 11:33:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author: Maxim Chernyakhovich>
-- Create date: <Create Date: 12.12.2022>
-- =============================================
ALTER PROCEDURE [dbo].[Fill_Orders]

AS
BEGIN

declare @Main_table table (OrderNumber nvarchar(20),Created datetime, DisplayName nvarchar(255), value nvarchar(20), OSP nvarchar(1000),FullName nvarchar(255),Region nvarchar(20), TypeContentsId int, OrderTypeId int, OrderStatusId int,OrderID int)
declare @EventID bigint
select @EventID = next value for monitoring.dbo.procedureeventid
declare @ProcedureName nvarchar(25) = 'Fill_Orders'
exec addlog 'Scheduler', 'SQL',@ProcedureName, 'START' ,''

;with E as (select 
format(A.Created, 'yyyy-MM-dd HH:mm') as Created
,cast(convert(float, A.value) as int)  as value
,B.DisplayName
--,A.department
,iif(A.department like '%[0-9][0-9][0-9][0-9][0-9][0-9]%' and len(A.department)>6,(select value from string_split(A.department,' ') where value like '%[0-9][0-9][0-9][0-9][0-9][0-9]%' and len(value)=6), A.department) as department
,ANU.FullName
,isnull(ANu.region,'Unknown') as Region
,TC.id as TypeContentsId
,OD.OrderId
,1 as OrderTypeId
,1 as OrderStatusId
,isnull(OS.CurrentOrderNumbForRegion,0) as CurrentOrderNumbForRegion
from r78planshet.webform.dbo.answers A
join r78planshet.webform.dbo.AspNetUsers ANU on A.UserId = ANU.Id
join r78planshet.webform.dbo.Elements E on A.ElementId = E.id
join  r78planshet.webform.dbo.Blocks B on B.id = E.BlockId
left join (
select Region,isnull(max(OrderNumber),0) as CurrentOrderNumbForRegion from Orders O
join OrderStatus OS2 on OS2.OrderId = O.id and DateStatusCreation > concat(datepart(year,getdate()),'.01.01')
 group by Region 
	) OS on OS.Region = ANU.Region
left join OrderStatus OD on  OD.StatusId=1 and 
  format(OD.DateStatusCreation,'yyyy-MM-dd HH:mm') = format(A.[Created],'yyyy-MM-dd HH:mm') and 
  OD.OSP = A.Department and OD.Account = ANU.FullName
left join [TypeContents] TC on TC.Name = concat(substring(B.DisplayName,0,len(B.DisplayName)-4),'.')
where elementid in(select id from r78planshet.webform.dbo.Elements 
          where BlockId in 
            (select id from r78planshet.webform.dbo.Blocks 
              where formid = (select id from r78planshet.webform.dbo.Forms where name ='Вторсырье')))
              and A.Created between (SELECT max([DateStatusCreation])FROM [Recyclables_Prod].[dbo].[OrderStatus] where statusid = 1) and dateadd(MINUTE, -1, getdate())--'2023-01-19 18:58:59.000'--'2022-01-01 00:00:01.000' and '2022-12-31 23:59:59.000'
)

insert into @Main_table select (ROW_number() over (partition by region,displayname order by Created,Department) +CurrentOrderNumbForRegion) as OrderNumber
,Created
,DisplayName
,Value
,Department
,FullName
,Region
,TypeContentsId
,OrderTypeId
,OrderStatusId
,null as OrderId
from E where orderid is null
order by 1,5

exec Monitoring.dbo.WriteLog @ProcedureName,@EventID,'Info','Insert from @Main_table to Orders, OrdeStatus, OrderContents'

begin try 
BEGIN TRAN
insert into Orders (OrderNumber, OSP, OrderTypeID, Region) 
select OrderNumber, OSP, OrderTypeID, Region from @Main_table 
group by OrderNumber, OSP, OrderTypeID, Region


insert into OrderStatus (OrderId, StatusID, DateStatusCreation, Account, OSP, Comment) 
select O.id, M.OrderStatusId, M.created, M.FullName, M.OSP, '' from @Main_table M
left join Orders O on O.OrderNumber = M.OrderNumber and m.Region = O.Region and m.osp = O.OSP
left join OrderStatus OS on OS.OrderId = O.Id and  M.created = OS.DateStatusCreation
group by O.id, M.OrderStatusId, M.created, M.FullName, M.OSP


insert into OrderContents (OrderId, TypeContentsId, Amount, ChangedAmount)
select O.id, M.TypeContentsId, M.Value, null from @Main_table M
left join Orders O on O.OrderNumber = M.OrderNumber and m.Region = O.Region and m.osp = O.OSP
left join OrderStatus OS on OS.OrderId = O.Id and  M.created = OS.DateStatusCreation

COMMIT TRAN
end try
begin catch
declare @err_num varchar(50) = (select ERROR_NUMBER() AS ErrorNumber)
declare @err_mes varchar(50) = (select ERROR_MESSAGE() AS ErrorMessage)
declare @message varchar(1100) = (select 'NUMBER: ' + @err_num + 'MESSAGE: ' + @err_mes)
exec addlog 'Scheduler', 'SQL',@ProcedureName, 'ERROR' ,@message

rollback TRAN
end catch
exec addlog 'Scheduler', 'SQL',@ProcedureName, 'END' ,''

END
