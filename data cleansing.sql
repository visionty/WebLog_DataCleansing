CREATE TABLE [dbo].[WebLogStg](
   [IP] [varchar](200) NULL,
   [junk1] [varchar](50) NULL,
   [junk2] [varchar](50) NULL,
   [conTime] [varchar](250) NULL,
   [junk3] [varchar](50) NULL,
   [Page] [varchar](400) NULL,
   [junk4] [varchar](50) NULL,
   [Size] [varchar](200) NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[VideoWebLog](
   [IP] [varchar](100) NOT NULL,
   [connectTime] [datetime] NULL,
   [WebPage] [varchar](300) NOT NULL,
   [size] [int] NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[WebLogAudit](
   [Number of Rows After Bulk Insert] int,
   [Rows in Staging] int,
   [Rows after Data Cleaning] int,
   [Rows in Final table] int
) ON [PRIMARY]


IF (OBJECT_ID('spWebLog') IS NOT NULL)
  DROP PROCEDURE spWebLog
GO
CREATE PROC spWebLog
   @Filepath VARCHAR (200)
AS
BEGIN
   -- Truncate the staging table before loading
   TRUNCATE TABLE WebLogStg;

 -- Use dynamic SQL to bulk insert the flat file to staging table
  DECLARE @Query varchar (MAX) 
  DECLARE @RowCountBulkInsert int
  DECLARE @RowCountWebLogStg int
  DECLARE @RowCountCleansing int
  DECLARE @RowCountFinal int

  SET @Query =' BULK INSERT WebLogStg
FROM''' +  @Filepath + '''WITH (FIRSTROW = 1,
FIELDTERMINATOR = ''\t'',
ROWTERMINATOR = ''\n'',
MAXERRORS=99999999)';

   EXEC (@Query); -- Execute dynamic SQL to bulk insert to staging table
   SET @RowCountBulkInsert = @@ROWCOUNT
   SELECT @RowCountWebLogStg = COUNT(*) FROM WebLogStg
 

   -- Clean each useful column and load to destination table

TRUNCATE TABLE WebLog
INSERT INTO WebLog (IP, connectTime, WebPage, size)
SELECT RTRIM(LTRIM(IP)), 
CONVERT(datetime, CONCAT(SUBSTRING(conTime, 2, 11), ' ', SUBSTRING(conTime, 14, 21)), 106),
REPLACE(Page, 'GET', ''), 
REPLACE(SUBSTRING(Size, 1, 3), char(9), '') 
FROM WebLogStg
WHERE Size <> '-' AND (Page like '%video%' AND Page like 'GET%')

SET @RowCountCleansing = @@ROWCOUNT

SELECT @RowCountFinal = COUNT(*) FROM WebLog

TRUNCATE TABLE WebLogAudit
INSERT INTO WebLogAudit
VALUES (@RowCountBulkInsert, @RowCountWebLogStg, @RowCountCleansing, @RowCountFinal)


END

-- Execute the stored procedure
EXEC spWebLog 'C:\SQL2014\Projects\Weblog\WebLogAccess.log';
