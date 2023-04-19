CREATE PROCEDURE [DataCleansing].[ScrubBulkInformation]
AS
	PRINT 'Scrubbing bulk information.'

	-- Truncate tables.
	-- Delete rows.

	-- Sanitize the remaining data
	-- to prevent sharing sensitive information.
	-- But do your truncates and deletes first
	-- so that the sanitize process has less data to work against
	-- and therefore finishes faster.

	/* *** ALWAYS REMEMBER TO SANITIZE AFTER SCRUBBING! *** */
	PRINT 'Always remember to sanitize after scrubbing!'
	EXEC [DataCleansing].[ScrubSensitiveInformation]
RETURN 0
