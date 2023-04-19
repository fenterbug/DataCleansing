CREATE PROCEDURE [DataCleansing].[CreateDatabaseCopy]
	@SourceDatabaseName nvarchar(255) = null,
	@TargetDatabaseName nvarchar(255) = null
AS
	-- Based on Jochen van Wylick's response to the StackOverflow question at https://stackoverflow.com/questions/2095910/sql-script-to-copy-a-database
	DECLARE @SourceDatabaseLogicalName nvarchar(255)
	DECLARE @SourceDatabaseLogicalNameForLog nvarchar(255)
	DECLARE @query nvarchar(2048)
	DECLARE @DataFolder nvarchar(2048)
	DECLARE @TargetDataFile nvarchar(2048)
	DECLARE @LogFolder nvarchar(2048)
	DECLARE @TargetLogFile nvarchar(2048)
	DECLARE @BackupDirectory NVARCHAR(255)
	DECLARE @BackupFile nvarchar(2048)

	-- ****************************************************************
	-- * Set up our data variables.

	-- Name of the source database
	IF (@SourceDatabaseName IS NULL) SELECT @SourceDatabaseName = db_name() -- Default to the current database
	-- Remove square brackets in case we need to use the this name in later statements
	IF (LEFT(@SourceDatabaseName,1) = '[') SELECT @SourceDatabaseName = RIGHT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)
	IF (RIGHT(@SourceDatabaseName,1) = ']') SELECT @SourceDatabaseName = LEFT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)

	-- Name of the target database
	IF (@TargetDatabaseName IS NULL) SELECT @TargetDatabaseName = @SourceDatabaseName + '_copy'
	-- Remove square brackets in case we need to use the this name in later statements
	IF (LEFT(@TargetDatabaseName,1) = '[') SELECT @TargetDatabaseName = RIGHT (@TargetDatabaseName, Len(@TargetDatabaseName) - 1)
	IF (RIGHT(@TargetDatabaseName,1) = ']') SELECT @TargetDatabaseName = LEFT (@TargetDatabaseName, Len(@TargetDatabaseName) - 1)

	-- Logical name of the DB and directory for data files
	SELECT   @SourceDatabaseLogicalName = [master].[sys].[master_files].[name],
	         @DataFolder = REVERSE (RIGHT (REVERSE ([master].[sys].[master_files].[physical_name]), LEN([master].[sys].[master_files].[physical_name]) - CHARINDEX('\',REVERSE ([master].[sys].[master_files].[physical_name]))))
	FROM     [master].[sys].[master_files]
	   INNER JOIN [master].[sys].[databases] ON
	         [master].[sys].[databases].[database_id] = [master].[sys].[master_files].[database_id]
	WHERE    [master].[sys].[databases].[name] = @SourceDatabaseName
	     AND [master].[sys].[master_files].[type_desc] = 'ROWS'

	-- Logical name of the DB log and directory for log files
	SELECT   @SourceDatabaseLogicalNameForLog = [master].[sys].[master_files].[name],
	         @LogFolder = REVERSE (RIGHT (REVERSE ([master].[sys].[master_files].[physical_name]), LEN([master].[sys].[master_files].[physical_name]) - CHARINDEX('\',REVERSE ([master].[sys].[master_files].[physical_name]))))
	FROM     [master].[sys].[master_files]
	   INNER JOIN [master].[sys].[databases] ON
	         [master].[sys].[databases].[database_id] = [master].[sys].[master_files].[database_id]
	WHERE    [master].[sys].[databases].[name] = @SourceDatabaseName
	     AND [master].[sys].[master_files].[type_desc] = 'LOG'

	-- Make sure we have directory separators as needed.
	IF (RIGHT (@DataFolder, 1) <> '\') SELECT @DataFolder = @DataFolder + '\'
	IF (RIGHT (@LogFolder, 1) <> '\') SELECT @LogFolder = @LogFolder + '\'

	-- Set file name
	SET @TargetDataFile = @DataFolder + @TargetDatabaseName + '.mdf';
	SET @TargetLogFile = @LogFolder + @TargetDatabaseName + '.ldf';

	-- Add square brackets back in to make sure we don't run into any reserved words
	IF (LEFT(@SourceDatabaseName,1) <> '[') SELECT @SourceDatabaseName = '[' + @SourceDatabaseName
	IF (RIGHT(@SourceDatabaseName,1) <> ']') SELECT @SourceDatabaseName = @SourceDatabaseName + ']'
	IF (LEFT(@TargetDatabaseName,1) <> '[') SELECT @TargetDatabaseName = '[' + @TargetDatabaseName
	IF (RIGHT(@TargetDatabaseName,1) <> ']') SELECT @TargetDatabaseName = @TargetDatabaseName + ']'

	-- ****************************************************************
	-- * Time to perform some actions.

	-- Drop Target Database if exists
	IF EXISTS(SELECT * FROM [master].[sys].[databases] WHERE name = @TargetDatabaseName)
	BEGIN
		PRINT 'Dropping the pre-existing target database.'
		SET @query = 'DROP DATABASE ' + @TargetDatabaseName
		PRINT 'Executing query : ' + @query;
		EXEC (@query)
	END
	PRINT 'OK!'

	PRINT 'Backuping up the source database.'
	EXEC [DataCleansing].[CreateDatabaseBackup] @SourceDatabaseName, @BackupFile = @BackupFile OUTPUT

	-- Restore database from @BackupFile into @DataFile and @LogFile
	PRINT 'Restoring that backup as the new target database.'
	SET @query = 'RESTORE DATABASE ' + @TargetDatabaseName + ' FROM DISK = ' + QUOTENAME(@BackupFile,'''') 
	SET @query = @query + ' WITH MOVE ' + QUOTENAME(@SourceDatabaseLogicalName,'''') + ' TO ' + QUOTENAME(@TargetDataFile ,'''')
	SET @query = @query + ' , MOVE ' + QUOTENAME(@SourceDatabaseLogicalNameForLog,'''') + ' TO ' + QUOTENAME(@TargetLogFile,'''')
	PRINT 'Executing query : ' + @query
	EXEC (@query)
	PRINT 'OK!'

	-- Clean up the file system
	PRINT 'Deleting our interim database backup.'
	EXEC [master].[sys].[xp_delete_files] @BackupFile

RETURN 0
