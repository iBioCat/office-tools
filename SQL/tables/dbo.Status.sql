USE [Test_Recyclables]
GO
/****** Object:  Table [dbo].[Status]    Script Date: 19.12.2022 10:41:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Status](
	[Id] [int] NOT NULL,
	[Name] [nvarchar](1000) NOT NULL,
	[OrderTypeId] [int] NOT NULL,
 CONSTRAINT [PK_Status] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Status]  WITH NOCHECK ADD  CONSTRAINT [FK_Status_OrderTypes] FOREIGN KEY([OrderTypeId])
REFERENCES [dbo].[OrderTypes] ([Id])
GO
ALTER TABLE [dbo].[Status] NOCHECK CONSTRAINT [FK_Status_OrderTypes]
GO
