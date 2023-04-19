CREATE PROCEDURE [DataCleansing].[CreateSanitizedCopy]
	@SourceDatabaseName nvarchar(255) = null,
	@TargetDatabaseName nvarchar(255) = null
AS
	DECLARE @Query nVarChar(2048)

	-- Name of the source database
	IF (@SourceDatabaseName IS NULL) SELECT @SourceDatabaseName = db_name() -- Default to the current database
	-- Remove square brackets. We don't want them yet.
	IF (LEFT(@SourceDatabaseName,1) = '[') SELECT @SourceDatabaseName = RIGHT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)
	IF (RIGHT(@SourceDatabaseName,1) = ']') SELECT @SourceDatabaseName = LEFT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)

	-- Remove square brackets in case we need to use the this name in later statements
	IF (LEFT(@TargetDatabaseName,1) = '[') SELECT @TargetDatabaseName = RIGHT (@TargetDatabaseName, Len(@TargetDatabaseName) - 1)
	IF (RIGHT(@TargetDatabaseName,1) = ']') SELECT @TargetDatabaseName = LEFT (@TargetDatabaseName, Len(@TargetDatabaseName) - 1)
	-- Name of the target database
	IF (@TargetDatabaseName IS NULL) SELECT @TargetDatabaseName = @SourceDatabaseName + '_sanitized'

	-- *****************************************

	EXEC [DataCleansing].[CreateDatabaseCopy] @SourceDatabaseName, @TargetDatabaseName
	
	SET @Query = N'EXEC [' + @TargetDatabaseName + '].[DataCleansing].[ScrubSensitiveInformation]'
	EXEC (@Query)

RETURN 0
