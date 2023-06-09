USE [Test_Recyclables]
GO
/****** Object:  Table [dbo].[TypeContents]    Script Date: 19.12.2022 10:41:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TypeContents](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[OrderTypeId] [int] NOT NULL,
	[Name] [nvarchar](1000) NOT NULL,
	[Measure] [nvarchar](10) NOT NULL,
	[Score] [int] NOT NULL,
 CONSTRAINT [PK_TypeContents] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
