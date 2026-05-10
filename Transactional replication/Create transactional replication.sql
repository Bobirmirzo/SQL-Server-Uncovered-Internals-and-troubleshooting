--------------------------------------------------------------
--------------------------------------------------------------
------------- Steps at distributor ---------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Step 1: Check if Distributor is already configured
EXEC sp_get_distributor;
-- Review output: installed = 1 means already configured
------------------------------------------------------------
-- Step 2: Declare variables (SINGLE BATCH – no GO here)
------------------------------------------------------------
DECLARE @distributor     sysname = N'WIN-FVVQ7PLR2I6';
DECLARE @distributionDB  sysname = N'distribution';
DECLARE @publisher       sysname = N'WIN-FRLGBC5IPSH';
DECLARE @directory       nvarchar(500) = N'\\WIN-FVVQ7PLR2I6\snapshotFolder';
------------------------------------------------------------
-- Step 3: Configure Distributor
------------------------------------------------------------
USE master;
BEGIN
    EXEC sp_adddistributor
        @distributor = @distributor,
        @password = N'MyDistributorPassword$$';
END
------------------------------------------------------------
-- Step 4: Create distribution database (if not exists)
------------------------------------------------------------
IF DB_ID(@distributionDB) IS NULL
BEGIN
    EXEC sp_adddistributiondb
        @database = @distributionDB,
        @security_mode = 1;
END
------------------------------------------------------------
-- Step 5: Configure Publisher at Distributor
------------------------------------------------------------
-- DO NOT switch context to [distribution] before DB exists
EXEC sp_adddistpublisher
    @publisher = @publisher,
    @distribution_db = @distributionDB,
    @security_mode = 1,
    @working_directory = @directory,
    @password = N'MyPublisherPassword$$';
------------------------------------------------------------
-- Step 6: Validate configuration
------------------------------------------------------------
EXEC sp_get_distributor;
SELECT name FROM sys.databases WHERE name = @distributionDB;

