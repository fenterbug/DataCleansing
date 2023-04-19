CREATE PROCEDURE [DataCleansing].[ScrubSensitiveInformation]
AS
	-- This procedure should remove or obfuscate any sensitive data contained within the database.
		-- Delete personally-identifying information such as names, addresses, SSNs.
		-- Maybe delete trade secrets?
		-- Financial information?
		-- Health information?

	PRINT 'Scrubbing sensitive information.'
RETURN 0
