USE [Test_Recyclables]
GO
/****** Object:  Table [dbo].[OrderContents]    Script Date: 19.12.2022 10:41:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderContents](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[OrderId] [int] NOT NULL,
	[TypeContentsId] [int] NOT NULL,
	[Amount] [int] NOT NULL,
	[ChangedAmount] [int] NULL,
 CONSTRAINT [PK_OrderContents] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OrderContents]  WITH NOCHECK ADD  CONSTRAINT [FK_OrderContents_Orders] FOREIGN KEY([OrderId])
REFERENCES [dbo].[Orders] ([Id])
GO
ALTER TABLE [dbo].[OrderContents] NOCHECK CONSTRAINT [FK_OrderContents_Orders]
GO
ALTER TABLE [dbo].[OrderContents]  WITH CHECK ADD  CONSTRAINT [FK_OrderContents_TypeContents] FOREIGN KEY([TypeContentsId])
REFERENCES [dbo].[TypeContents] ([Id])
GO
ALTER TABLE [dbo].[OrderContents] CHECK CONSTRAINT [FK_OrderContents_TypeContents]
GO
