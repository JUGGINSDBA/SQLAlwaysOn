$srv1 = New-Object Microsoft.SqlServer.Management.Smo.Server 'SQL01\SPX_001,45001'
$srv2 = New-Object Microsoft.SqlServer.Management.Smo.Server 'SQL02\SPX_001,45001'
$srv3 = New-Object Microsoft.SqlServer.Management.Smo.Server 'SQL03\SPX_001,45001'

New-DbaEndpoint -sqlinstance $srv1 -type DatabaseMirroring -Port 5055 -name ag_test -Confirm:$false
New-DbaEndpoint -sqlinstance $srv2 -type DatabaseMirroring -Port 5055 -name ag_test -Confirm:$false
New-DbaEndpoint -sqlinstance $srv3 -type DatabaseMirroring -Port 5055 -name ag_test -Confirm:$false

Start-DbaEndpoint -SqlInstance $SRV1 -Endpoint AG_TEST
Start-DbaEndpoint -SqlInstance $SRV2 -Endpoint AG_TEST
Start-DbaEndpoint -SqlInstance $SRV3 -Endpoint AG_TEST

New-DbaAvailabilityGroup -Primary $SRV1 -Secondary $SRV2 -Name nw105 -EndpointUrl 'TCP://SQL01.contoso.local:5055', 'TCP://sql02.contoso.local:5055' -confirm:$false

## confirm number of replicas if possible

# Test-DbaAvailabilityGroup -sqlinstance $srv1 -availabilitygroup nw999 -AddDatabase test_db -SeedingMode Automatic

Add-DbaAgDatabase -SqlInstance $srv1 -AvailabilityGroup nw105 -Database test_db -Confirm:$false -SeedingMode Automatic -Secondary $srv2

Get-DbaAvailabilityGroup -sqlinstance $srv1 -AvailabilityGroup nw999 | Add-DbaAgReplica -SqlInstance $SRV3 -FailoverMode Manual -EndpointUrl 'TCP://sql03.contoso.local:5055' -Confirm:$false

## need separate mirroring port for each instance
## only allowed one database mirroring endpoint
## need to delete database mirroring endpoints if they exist - need to check if mirroring endpoint exists by default
## need to assign dba rights to db before put in availability group

# Add-DbaAgDatabase -SqlInstance $srv1 -AvailabilityGroup nw999 -Database test_db -Confirm:$false -SeedingMode Automatic

# Pre-Stage Listener - does this have to happen - makes sense...

$ag_Listener = "Listener"

Add-DbaAgListener -SqlInstance $srv1 -AvailabilityGroup nw99 -IPAddress 10.0.0.50 -SubnetMask 255.0.0.0 # -Name $ag_Listener

write-host "Listener detail is $($ag_Listener)"

## need to potentially schedule the below..

Copy-DbaLogin -source $srv1 -destination $srv2 -login gjuggins -ObjectLevel
