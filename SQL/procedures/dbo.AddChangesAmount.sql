USE [Recyclables_Test]
GO
/****** Object:  StoredProcedure [dbo].[AddChangesAmount]    Script Date: 31.01.2023 10:27:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author: Maxim Chernyakhovich>
-- Create date: <Create Date: 14.12.2022>
-- =============================================
ALTER PROCEDURE [dbo].[AddChangesAmount]
	@OrderId int
	,@values nvarchar(200)
	,@status int 
	,@Account nvarchar(45)
	,@Comment nvarchar(1000)
	
AS
BEGIN
	SET NOCOUNT ON
	--declare @orderid int = (select id from orders where OrderNumber = @OrderNumber)
	--declare @orderid int = (select o.id from orders o left join orderstatus os on o.Id = os.OrderId where OrderNumber = @OrderNumber and DateStatusCreation = @OrderData)
	declare @OSP nvarchar(100) = (SELECT distinct Department FROM [R78planshet].[WebForm].[dbo].[AspNetUsers] where UserName in(@Account))
	declare @FullName nvarchar(100) = (SELECT distinct FullName FROM [R78planshet].[WebForm].[dbo].[AspNetUsers] where UserName in(@Account))
	declare @ProcedureName nvarchar(25) = 'AddChangesAmount'
	declare @ordernumber nvarchar(1000) = (select distinct ordernumber from orders where id = @OrderId)

	--log
	--exec addlog @Account, 'SQL', @ProcedureName, 'Start', ''
		
	declare @values_array table (Id int, value int) 
	DECLARE @array varchar(200) = iif(@values = '','0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0', @values) --@values--'1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22'
	insert into @values_array
	select ROW_NUMBER() OVER(ORDER BY (Select 0)) AS id, cast(value as int) as ChangedAmount from string_split(@array, ',')

	declare @check_ins int = (select count(*) as check_insert  from orderstatus where orderid = @orderid and statusid > 1)


	if @check_ins = 0
		begin try 
		BEGIN TRAN



		UPDATE OrderContents
		SET ChangedAmount = (case 
								when TypeContentsId = 1 then (select value from @values_array where id = 1)
								when TypeContentsId = 2 then (select value from @values_array where id = 2)
								when TypeContentsId = 3 then (select value from @values_array where id = 3)
								when TypeContentsId = 4 then (select value from @values_array where id = 4)
								when TypeContentsId = 5 then (select value from @values_array where id = 5)
								when TypeContentsId = 6 then (select value from @values_array where id = 6)
								when TypeContentsId = 7 then (select value from @values_array where id = 7)
								when TypeContentsId = 8 then (select value from @values_array where id = 8)
								when TypeContentsId = 9 then (select value from @values_array where id = 9)
								when TypeContentsId = 10 then (select value from @values_array where id = 10)
								when TypeContentsId = 11 then (select value from @values_array where id = 11)
								when TypeContentsId = 12 then (select value from @values_array where id = 12)
								when TypeContentsId = 13 then (select value from @values_array where id = 13)
								when TypeContentsId = 14 then (select value from @values_array where id = 14)
								when TypeContentsId = 15 then (select value from @values_array where id = 15)
								when TypeContentsId = 16 then (select value from @values_array where id = 16)
								when TypeContentsId = 17 then (select value from @values_array where id = 17)
								when TypeContentsId = 18 then (select value from @values_array where id = 18)
								when TypeContentsId = 19 then (select value from @values_array where id = 19)
								when TypeContentsId = 20 then (select value from @values_array where id = 20)
								when TypeContentsId = 21 then (select value from @values_array where id = 21)
								when TypeContentsId = 22 then (select value from @values_array where id = 22)
							end)
		WHERE OrderId = @OrderId 
		;
		insert into OrderStatus(OrderId, StatusId,DateStatusCreation,Account,Comment,OSP)
		values(@orderid,@status,getdate(),@FullName, @Comment, @OSP)

		select 'good' as good
		declare @message_good varchar(1100) = (select 'Ok.' + 'Ordernumber: '+@ordernumber+' Array: '+@array + '. Orderid: '+ @OrderId +'. Values: ' + @values + '. Status: ' +@status +'. Comment: ' + @comment)
		exec addlog @account, 'SQL', @ProcedureName, 'INFO',@message_good

		COMMIT TRAN
		end try
		begin catch
			declare @err_num varchar(50) = (select ERROR_NUMBER() AS ErrorNumber)
			declare @err_mes varchar(50) = (select ERROR_MESSAGE() AS ErrorMessage)
			declare @message varchar(1100) = (select 'NUMBER: ' + @err_num + 'MESSAGE: ' + @err_mes)

			exec addlog @account, 'SQL',@ProcedureName, 'Error' ,@message
		rollback TRAN
		end catch
	else
		select 'bad' as bad

	--exec addlog @account, 'SQL', @ProcedureName, 'END',''
END
