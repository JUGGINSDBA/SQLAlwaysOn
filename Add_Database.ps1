
import-module sqlserver

$configData = get-content c:\AG_DB.json -Raw | ConvertFrom-Json
$sqlInstance = $configData.DbaAgDatabase.InstanceName
$sqlPort = $configData.DbaAgDatabase.SQLPort
$HADRPrimary = $configData.DbaAgDatabase.Primary
$srvConnect = New-Object Microsoft.SqlServer.Management.Smo.Server "$($HADRPrimary)\$($sqlInstance)"
# $srvConnect = New-Object Microsoft.SqlServer.Management.Smo.Server "$($HADRPrimary)\$($sqlInstance),$($sqlPort)"
$AGroup = $configData.DbaAgDatabase.AGroup
$AGDatabase = $configData.DbaAgDatabase.Database
$AGSeeding = $configData.DbaAgDatabase.SeedingMode


write-host "Primary is $($HADRPrimary)"

write-host $srvConnect

## need to assign dba rights to db before put in availability group

Add-DbaAgDatabase -SqlInstance $srvConnect -AvailabilityGroup $AGroup -Database $AGDatabase -Confirm:$false -SeedingMode $AGSeeding

# Pre-Stage Listener - does this have to happen - makes sense...



# Copy-DbaLogin -source $srv1 -destination $srv2 -login gjuggins -ObjectLevel



# Add-DbaAgDatabase -SqlInstance SQL01\SPX_001,45001 -AvailabilityGroup ag_TEST2 -Database TEST_DB -Confirm:$false -SeedingMode AUTOMATIC
