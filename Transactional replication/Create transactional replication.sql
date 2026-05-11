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

--After configuring distributor, we will switch to configuring publisher.

--------------------------------------------------------------
--------------------------------------------------------------
------------- Steps at publisher ---------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Login to publisher and switch context to the target publishing database. 
use [DatabaseToBePublished]
exec sp_replicationdboption @dbname = N'DatabaseToBePublished', @optname = N'publish', @value = N'true'
GO

/***************************************
 Step 1: Create Transactional Publication. 
***************************************/
use [DatabaseToBePublished]
exec sp_addpublication @publication = N'MyTestPublication',
@description = N'Transactional publication of database ''DatabaseToBePublished'' from Publisher ''WIN-FRLGBC5IPSH''.',
@sync_method = N'concurrent', @retention = 0, @allow_push = N'true', @allow_pull = N'true', @allow_anonymous = N'true',
@enabled_for_internet = N'false', @snapshot_in_defaultfolder = N'true', @compress_snapshot = N'false', @ftp_port = 21, 
@allow_subscription_copy = N'false', @add_to_active_directory = N'false', @repl_freq = N'continuous', @status = N'active',
@independent_agent = N'true', @immediate_sync = N'true', @allow_sync_tran = N'false', @allow_queued_tran = N'false',
@allow_dts = N'false', @replicate_ddl = 1, @allow_initialize_from_backup = N'false', @enabled_for_p2p = N'false', 
@enabled_for_het_sub = N'false'
GO

/********************************************
 Step 2: Create Snapshot Agent for Publication
********************************************/
exec sp_addpublication_snapshot
@publication = N'MyTestPublication', 
@frequency_type = 1, @frequency_interval = 1, 
@frequency_relative_interval = 1, @frequency_recurrence_factor = 0,
@frequency_subday = 8, @frequency_subday_interval = 1, @active_start_time_of_day = 0,
@active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @job_login = null, 
@job_password = null, @publisher_security_mode = 1

/***************************************
 Step 3: Add Article (Table) to Publication
***************************************/
use [DatabaseToBePublished]
exec sp_addarticle @publication = N'MyTestPublication', @article = N'TableToBeReplicated', 
@source_owner = N'dbo', @source_object = N'TableToBeReplicated', @type = N'logbased',
@description = null, @creation_script = null, @pre_creation_cmd = N'drop', 
@schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual',
@destination_table = N'TableToBeReplicated', @destination_owner = N'dbo', 
@vertical_partition = N'false', @ins_cmd = N'CALL sp_MSins_dboTableToBeReplicated', 
@del_cmd = N'CALL sp_MSdel_dboTableToBeReplicated', @upd_cmd = N'SCALL sp_MSupd_dboTableToBeReplicated'
GO
