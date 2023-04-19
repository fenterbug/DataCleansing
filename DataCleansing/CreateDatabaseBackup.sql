CREATE PROCEDURE [DataCleansing].[CreateDatabaseBackup]
	@SourceDatabaseName nVarChar(255) = null,
	@BackupFile nVarChar(255) OUTPUT
AS
	DECLARE @SourceDatabaseLogicalName nVarChar(255)
	DECLARE @BackupDirectory nVarChar(255)
	DECLARE @query nVarChar(2048)

	-- Name of the source database
	IF (@SourceDatabaseName IS NULL) SELECT @SourceDatabaseName = db_name() -- Default to the current database
	-- Remove square brackets. We don't want them yet.
	IF (LEFT(@SourceDatabaseName,1) = '[') SELECT @SourceDatabaseName = RIGHT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)
	IF (RIGHT(@SourceDatabaseName,1) = ']') SELECT @SourceDatabaseName = LEFT (@SourceDatabaseName, Len(@SourceDatabaseName) - 1)

	-- Logical name of the source database
	SELECT   @SourceDatabaseLogicalName = [master].[sys].[master_files].[name]
	FROM     [master].[sys].[master_files]
	   INNER JOIN [master].[sys].[databases] ON
	         [master].[sys].[databases].[database_id] = [master].[sys].[master_files].[database_id]
	WHERE    [master].[sys].[databases].[name] = @SourceDatabaseName
	     AND [master].[sys].[master_files].[type_desc] = 'ROWS'

	-- Read the current SQL Server default backup location
	EXEC [master].[dbo].[xp_instance_regread]
		@rootkey = 'HKEY_LOCAL_MACHINE',
		@key = 'Software\Microsoft\MSSQLServer\MSSQLServer', 
		@value_name = 'BackupDirectory',
		@BackupDirectory = @BackupDirectory OUTPUT
	IF (RIGHT (@BackupDirectory, 1) <> '\') SELECT @BackupDirectory = @BackupDirectory + '\'

	-- This defines our OUTPUT value
	SET @BackupFile = @BackupDirectory + @SourceDatabaseLogicalName + '.bak'

	-- Add square brackets back in to make sure we don't run into any reserved words
	IF (LEFT(@SourceDatabaseName,1) <> '[') SELECT @SourceDatabaseName = '[' + @SourceDatabaseName
	IF (RIGHT(@SourceDatabaseName,1) <> ']') SELECT @SourceDatabaseName = @SourceDatabaseName + ']'

	SET @query = 'BACKUP DATABASE ' + @SourceDatabaseName + ' TO DISK = ' + QUOTENAME(@BackupFile,'''')
	EXEC (@query)
RETURN 0
