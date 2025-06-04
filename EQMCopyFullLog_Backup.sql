---------------------------------------------------------------------------------------------------------------------------------------------------
/* Script for Easy, Quick & Manual database backup as Copy_Only or Full Database or Transaction Log backup with other options
 * Created on 10/16/2024 by Hargie Curato
 * Updated on 11/04/2024 by Hargie Curato with the following:
    - Replaced (IF NOT EXISTS (SELECT Name FROM sys.databases WHERE Name  = @DBName) line by ELSE keyword.
 * Updated on 11/12/2024 by Hargie Curato with the following:
    - Remove backlash string (\) on @BackupPath variable. Change the --description to match with the new changes on @BackupPath variable.
    - Add the backlash string (\) on @FileName variable instead.
    - Add semicolon (;) after the keywork CHECKSUM on both @Copy_Only and @BackupFull variables
    - Shorten and rename the @BackupSQLString Full to @BackupFull
    - Add (+ '\') strings after @BackupPath variable inside @FileNameFull variable
 * Updated on 12/19/2024 by Hargie Curato with the following:
    - Added new variable @CustomBackupName where you can specify the custom name for your backup. 
      This variable is then used in the @FileName and @BackupName variables to create the backup file with the desired name.
    - Added the @FinalBackupName variable which is set based on whether @CustomBackupName is provided. If @CustomBackupName is empty, it defaults 
      to @DBName. This way, you can optionally provide a custom backup name, and if you don't, the script will use the database name as 
      the backup name.
    - Added a new variable @Overwrite to control whether the backup file should be overwritten. If @Overwrite is set to 1, the INIT option is used to 
	  overwrite the existing backup file. If @Overwrite is set to 0, the NOINIT option is used to append to the existing backup file.
    - Added print statements to indicate whether the backup file has been overwritten or appended based on the value of the @Overwrite variable.
    - Added a new variable @FastBackup to enable faster backup. If @FastBackup is set to 1, the BUFFERCOUNT and MAXTRANSFERSIZE options are used to 
	  speed up the backup process. Note that enabling this option will consume more CPU and RAM resources.
 * Updated on 06/04/2025 by Hargie Curato with the following:
    - QUOTED_IDENTIFIER set to ON; Replace all Double quotation marks (") by Double Single quotation marks ('')
    - Change @BackupDate format to include not only day, month, year but also hour, minute, seconds, & fractional seconds.
    - Include Transaction log backup
    - New Dynamically inputed variables: @CopyOnlyBackupName for Copy_Only database backup & @LogBackupName for Transaction Log backup
    - Rename the SQL script file from CopyOnly_or_FullDB_Backup.sql to EQMCopyFullLog_Backup.sql. EQM stands for Easy, Quick, Manual
*/
---------------------------------------------------------------------------------------------------------------------------------------------------

/***** EQMCopyFullLog_Backup.sql *****/

USE [master];
GO
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Declare the preliminary variables (Your input is needed!)
DECLARE @DBName NVARCHAR(255) = N'EFSDB'; -- Type the database that you want to backup
DECLARE @BackupPath NVARCHAR(MAX) = N'D:\OneDrive\MyExpenses\EFSDB\backup'; -- Type the folder path of the backup destination without backlash (\) at the end of path's name.
DECLARE @BackupType NVARCHAR(20) = N''; -- Type Copy_Only, Log or Leave it blank for a full database backup
DECLARE @CustomBackupName NVARCHAR(255) = N''; -- Custom backup name (optional)
DECLARE @Overwrite BIT = 0; -- Set to 1 to overwrite the existing backup file. Default value is 0.
DECLARE @FastBackup BIT = 0; -- Set to 1 to enable faster backup. Default value is 0.

-- Dynamically inputed variables
DECLARE @BackupDate NVARCHAR(50) = (SELECT FORMAT(GETDATE(), 'MM-dd-yyyy_HH-mm-ss-fff'));
DECLARE @FinalBackupName NVARCHAR(255) = CASE WHEN @CustomBackupName = N'' THEN @DBName ELSE @CustomBackupName END;
DECLARE @FileName NVARCHAR(MAX) = (N'' + 'N''' + @BackupPath + '\' + @FinalBackupName + N'_' + @BackupType + N'_' + @BackupDate + N'.bak''');
DECLARE @LogFileName NVARCHAR(MAX) = (N'' + 'N''' + @BackupPath + '\' + @FinalBackupName + N'_' + @BackupType + N'_' + @BackupDate + N'.trn''');
DECLARE @BackupName NVARCHAR(MAX) = (N'' + 'N''' + @FinalBackupName + N'-Full Database Backup' + ''',');
DECLARE @CopyOnlyBackupName NVARCHAR(MAX) = (N'' + 'N''' + @FinalBackupName + N'-Copy_Only Database Backup' + ''',');
DECLARE @LogBackupName NVARCHAR(MAX) = (N'' + 'N''' + @FinalBackupName + N'-TransactionLog Database Backup' + ''',');

-- Determine the INIT option based on the @Overwrite variable
DECLARE @InitOption NVARCHAR(20) = CASE WHEN @Overwrite = 1 THEN 'INIT' ELSE 'NOINIT' END;

-- Determine the fast backup options
DECLARE @FastBackupOptions NVARCHAR(MAX) = CASE WHEN @FastBackup = 1 THEN 'BUFFERCOUNT = 100, MAXTRANSFERSIZE = 4194304, ' ELSE '' END;

IF EXISTS (SELECT Name FROM sys.databases WHERE Name = @DBName)
BEGIN
    PRINT 'Database found: ' + @DBName;
    IF @BackupType = 'Copy_Only'
    BEGIN 
    PRINT ' ';
    PRINT 'Creating a Copy_Only Database Backup';
    DECLARE @Copy_Only NVARCHAR (MAX);
    SET @Copy_Only = (N'BACKUP DATABASE ' + QUOTENAME(@DBName) + N' TO DISK = ' + @FileName +  N'WITH ' + @BackupType + N', NOFORMAT, ' + @InitOption + N', ' + @FastBackupOptions + N'NAME = '+ @CopyOnlyBackupName + N' SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10, CHECKSUM;');
        EXEC sp_executesql @Copy_Only;
        PRINT CASE WHEN @Overwrite = 1 THEN 'The backup file has been overwritten.' ELSE 'The backup file has been appended.' END;
    END

    ELSE
    IF @BackupType = ''
    BEGIN
    PRINT ' ';
    PRINT 'Creating a Full Database Backup';
    DECLARE @BackupFull NVARCHAR (MAX);
    DECLARE @FileNameFull NVARCHAR (MAX) = (N'' + 'N''' + @BackupPath + '\' + @FinalBackupName + N'_FullDB_' + @BackupDate + N'.bak' + '''');
    SET @BackupFull = (N'BACKUP DATABASE ' + QUOTENAME(@DBName) + N' TO DISK = ' + @FileNameFull +  N'WITH ' + @BackupType + N'NOFORMAT, ' + @InitOption + N', ' + @FastBackupOptions + N'NAME = '+ @BackupName + N' SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10, CHECKSUM;');
        EXEC sp_executesql @BackupFull;
        PRINT CASE WHEN @Overwrite = 1 THEN 'The backup file has been overwritten.' ELSE 'The backup file has been appended or created a new one.' END;
    END

    ELSE
    IF @BackupType = 'Log'
    BEGIN
    PRINT ' ';
    PRINT 'Creating a Transaction Log Backup';
    DECLARE @LogBackup NVARCHAR (MAX);
    SET @LogBackup = (N' BACKUP LOG ' + QUOTENAME (@DBName) + N' TO DISK = ' + @LogFileName + N' WITH ' + N'NOFORMAT, ' + @InitOption + N', ' + @FastBackupOptions + N'NAME = '+ @LogBackupName + N' SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10, CHECKSUM;');
        EXEC sp_executesql @LogBackup
        PRINT CASE WHEN @Overwrite = 1 THEN 'The log backup file has been overwritten.' ELSE 'The log backup file has been appended or created a new one.' END;
    END

    ELSE
    BEGIN
        PRINT 'Invalid backup type specified: ' + @BackupType;
    END
END
ELSE
BEGIN
    PRINT N'Database backup did not start because the provided database is not found';
END
GO

/***** EQMCopyFullLog_Backup.sql *****/

