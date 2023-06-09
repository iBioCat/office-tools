USE [Test_Recyclables]
GO
/****** Object:  Table [dbo].[OrderStatus]    Script Date: 19.12.2022 10:41:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderStatus](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[OrderId] [int] NOT NULL,
	[StatusId] [int] NOT NULL,
	[DateStatusCreation] [datetime] NOT NULL,
	[Account] [nvarchar](45) NOT NULL,
	[OSP] [nvarchar](200) NOT NULL,
	[Comment] [nvarchar](1000) NULL,
 CONSTRAINT [PK_OrderStatus] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OrderStatus]  WITH NOCHECK ADD  CONSTRAINT [FK_OrderStatus_Orders] FOREIGN KEY([OrderId])
REFERENCES [dbo].[Orders] ([Id])
GO
ALTER TABLE [dbo].[OrderStatus] NOCHECK CONSTRAINT [FK_OrderStatus_Orders]
GO
ALTER TABLE [dbo].[OrderStatus]  WITH NOCHECK ADD  CONSTRAINT [FK_OrderStatus_OrderStatus] FOREIGN KEY([StatusId])
REFERENCES [dbo].[Status] ([Id])
GO
ALTER TABLE [dbo].[OrderStatus] NOCHECK CONSTRAINT [FK_OrderStatus_OrderStatus]
GO
