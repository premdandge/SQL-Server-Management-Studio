

SET NOCOUNT ON
GO
DECLARE @Now	datetime = getdate()
doitagian:
print datediff(second,@Now,getdate())
SET @Now = getdate();
raiserror('Delete Batch',-1,-1) WITH NOWAIT
DELETE TOP(100000) FROM [DBAperf_reports].[dbo].[DMV_DATABASE_FORECAST_DETAIL]
WHERE [RunDate] < GetDate()-90
IF @@ROWCOUNT = 100000 goto doitagian


