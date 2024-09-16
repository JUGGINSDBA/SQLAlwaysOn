# JSON file needed for this 
# More parameterisation needed 

Import-Module SQLsERVER

$backupDir = "C:\Program Files\Microsoft SQL Server\MSSQL15.SQL1\MSSQL\Backup"
$AGName = "AG01"
$primaryNode = $env:COMPUTERNAME
$databasesToIgnore = "master", "model", "msdb", "tempdb"
$myJSON = Get-Content c:\test.json | ConvertFrom-Json

###############################
# Begin Script
###############################

# Connect to sql instance and get databases
# $sqlinstance = New-Object -TypeName Microsoft.SQLServer.Management.Smo.Server("localhost")
$sqlinstance = New-Object -TypeName Microsoft.SQLServer.Management.Smo.Server("SQL01\SQL1")
# $sqlinstance = "SQL01\SQL1"
$dbs = $sqlinstance.Databases

# Iterate over all DBs found on this instance of SQL.
foreach($db in $dbs){

    #################################
    # AG and Ignore Checks
    #################################
    
    if($db.AvailabilityGroupName -ne "" -or $databasesToIgnore -contains $db.Name){ 
        Write-Host "$(Get-Date -format g) - INFO - $($db.Name) - Skipping because it is either in the ignore list, or already in an AG."
        continue 
    }

    Write-Host "$(Get-Date -format g) - INFO - $($db.Name) - Is not currently in the AG. "

    #################################
    # Recovery Model Checks
    #################################

    if($db.RecoveryModel -eq "Simple"){

        Write-Host "$(Get-Date -format g) - INFO - $($db.Name) - DB in Simple Recovery. Attempting to switch to Full Recovery model."

        try{
            # Change recovery model if Simple.
            $db.RecoveryModel = "Full";
            $db.Alter();
        }catch{
            # Write an error if change fails, and skip to next database. 
            Write-Host "$(Get-Date -format g) - ERROR - $($db.Name) - Failed to set databases to Full Recovery Model."
            continue 
        }

        Write-Host "$(Get-Date -format g) - INFO - $($db.Name) - Attemping to take a full backup server after recovery model change."
        try{
            # Create a SQL backup object for this database
            $dbBackup = new-object ("Microsoft.SqlServer.Management.Smo.Backup")
            $dbBackup.Database = $db.name
            # Set SQL backup location and type (e.g. Database, Log)
            $dbBackup.Devices.AddDevice("$backupDir\$($db.Name)_AAG_Setup.bak", "File")
            $dbBackup.Action = "Database"
            # Execute the backup
            $dbBackup.SqlBackup($sqlinstance)
        }catch{

            # Write an error if backup fails, and skip to next database. 
            Write-Host "$(Get-Date -format g) - ERROR - $($db.Name) - Failed attemping to take a backup."
            continue 
        }
    }

    #################################
    # Add Database to AG
    #################################

    Write-Host "$(Get-Date -format g) - INFO - $($db.Name) - Attemping to add database to AG on $primaryNode."

    try{
        # Run SQL Query to add current database to the AG.

        $queryPrimary = "ALTER AVAILABILITY GROUP [$($AGName)] ADD DATABASE [$($db.Name)]"
        Write-Host "$(Get-Date -format g) - INFO - $($db.Name) - $($primaryNode):" $queryPrimary
      #  Invoke-Sqlcmd -Query $queryPrimary

       

          Invoke-Sqlcmd -ServerInstance "SQL01\SQL1,40001" -Query $queryPrimary -Encrypt Optional

          }catch {
        # Write an error if it failed to add to AG and go to next database.  
        Write-Host "$(Get-Date -format g) - ERROR - $($db.Name) - $($primaryNode): Failed to add to AG"
        continue
    }
    # You can uncomment this exit if you want to do a test against the first db only. 
    # Exit 0

}