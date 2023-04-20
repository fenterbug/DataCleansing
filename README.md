# DataCleansing

This set of stored procedures will help in your efforts to manage personally-identifying data within database backups and copies.

## What You Need To Do

You have to do the hard work of implementing `ScrubSensitiveInformation` to remove any sensitive information in your database such as social security numbers, addresses, et al.

You also have to do the hard work of implementing `ScrubBulkInformation` to remove large sets of non-critical data such as logging, audits, and history. This is meant to reduce the gross size of the data in your database. It is assumed that when trimming bulk data, you will also want to cleans sensitive data as well. You will need to remember to include the call to `ScrubSensitiveInformation` as shown in the example.

## How To Use

If you need to create a copy of your data-- for example, when setting up a new client/user-- you can simply call `CreateSanitizedCopy`, providing an optional name for the new database. (See code.)

If you need to create a backup-- for example, to bring a database local for troubleshooting-- you can simply call `CreateSanizitedBackup`.

You may also choose to call `ScrubBulkInformation` on a schedule. If you do, you will probably **not** want it to also call `ScrubSensitiveInformation`.
