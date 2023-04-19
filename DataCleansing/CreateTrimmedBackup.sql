CREATE PROCEDURE [DataCleansing].[CreateTrimmedBackup]
	@SourceDatabaseName nvarchar(255) = null
AS
	DECLARE @BackupFile nVarChar(255)
	DECLARE @TargetDatabaseName nVarChar(255)

	-- Name of the source database
	IF (@SourceDatabaseName IS NULL) SELECT @SourceDatabaseName = db_name() -- Default to the current database
	-- Remove square brackets. We don't want them yet.
	IF (LEFT(@SourceDatabaseName,1) = '[') SELECT @SourceDatabaseName = RIGHT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)
	IF (RIGHT(@SourceDatabaseName,1) = ']') SELECT @SourceDatabaseName = LEFT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)

	SET @TargetDatabaseName = @SourceDatabaseName + '_trimmed'

	EXEC [DataCleansing].[CreateTrimmedCopy]  @SourceDatabaseName, @TargetDatabaseName
	EXEC [DataCleansing].[CreateDatabaseBackup] @TargetDatabaseName, @BackupFile = @BackupFile OUTPUT

	DECLARE @query VarChar(255)
	SET @query = 'DROP DATABASE ' + @TargetDatabaseName
	EXEC (@query)

	PRINT 'Your trimmed backup is at:'
	PRINT @BackupFile

RETURN 0
