import-module sqlserver

$configData = get-content c:\final.json -Raw | ConvertFrom-Json
$Replicas = $configData.Replicas
$sqlInstance = $configData.Replicas.InstanceName
$sqlPort = $configData.Replicas.Port
$HADRPrimary = $configData.DbaAgHadr.Primary
$HADRSecondary = $configData.DbaAgHadr.Secondary
$HADRTertiary = $configData.DbaAgHadr.Tertiary
$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SPX_001\MSSQLServer\HADR"
$srvConnect = New-Object Microsoft.SqlServer.Management.Smo.Server "$($z)\$($sqlInstance),$($sqlPort)"
$AGroup = $configData.DbaAgHadr.AGroup
$AGListener = $configData.DbaAgHadr.Listener
$ListenerIP1 = $configData.DbaAgHadr.ListenerIP1
$ListenerIP2 = $configData.DbaAgHadr.ListenerIP2
$ListenerSubnetMask = $configData.DbaAgHadr.SubnetMask

# Check connection to Instance
      
 foreach ($z in $Replicas.Name){
    try {
          $server = Connect-DbaInstance -SqlInstance $srvconnect
  } catch {
         write-host "Unable to connect to SQL Instance $($srvConnect)" 
         exit
  }
}
            
# Check and enable HADR 
       
 foreach ($z in $Replicas.Name){
 
$RegItems =
Invoke-command -ComputerName $z {
    [PSCustomObject]@{
    HADRCheck = (Get-ItemProperty -Path $using:RegKeyPath -Name 'HADR_Enabled').HADR_Enabled
       }
}

write-host $z, $RegItems.HADRCheck

  if($RegItems.HADRCheck -eq 1){write-host "it is enabled on server $($z) -- good news !!"
}

else{
    write-host "on $($Z) it is NOT enabled"

write-host "will need to enable"

write-host $srvConnect

Enable-DbaAgHadr -sqlinstance $srvConnect -Force -Confirm:$false  -Verbose

    }

}

# Check for and delete default mirroring endpoint if exists

foreach ($z in $Replicas.Name){
$srvConnect = New-Object Microsoft.SqlServer.Management.Smo.Server "$($z)\$($sqlInstance),$($sqlPort)"
    $CheckEndPoint = Get-DbaEndpoint -SqlInstance $srvconnect -Endpoint Hadr_Endpoint
    if ($CheckEndPoint -ne "Hadr_Endpoint")
        {write-host "Default HADR EndPoint does not exist on $($srvconnect)- Continuing"
}
else {
    write-host "Deleting default Endpoint on $($srvConnect)"
    Remove-DbaEndpoint -SqlInstance $srvconnect -Endpoint Hadr_Endpoint
    }
}

## Check for and create & start new mirroring endpoint if not exists

foreach ($z in $Replicas.Name){
$srvConnect = New-Object Microsoft.SqlServer.Management.Smo.Server "$($z)\$($sqlInstance),$($sqlPort)"
    $CheckNewEndPoint = Get-DbaEndpoint -SqlInstance $srvconnect -Endpoint ag_test
    if ($CheckNewEndPoint -eq $false)
        {write-host "New HADR EndPoint does not exist - Creating"
        New-DbaEndpoint -sqlinstance $srvconnect -type DatabaseMirroring -Port 5055 -name ag_test -Confirm:$false
        Start-DbaEndpoint -SqlInstance $srvconnect -Endpoint AG_TEST

}
else {
    write-host "New EndPoint already exists on $($srvConnect)"
     }
        

}

## Check for existence of Availability Group
# need to get server name outside of loop

$Primary = New-Object  Microsoft.SqlServer.Management.Smo.Server "$($HADRPrimary)\$($sqlInstance),$($sqlPort)"
$Secondary = New-Object  Microsoft.SqlServer.Management.Smo.Server "$($HADRSecondary)\$($sqlInstance),$($sqlPort)"
$Tertiary = New-Object  Microsoft.SqlServer.Management.Smo.Server "$($HADRTertiary)\$($sqlInstance),$($sqlPort)"

write-host $Primary

$OrigCheckAGGroup = Get-DbaAvailabilityGroup -SqlInstance $Primary -AvailabilityGroup $AGroup

$CheckAGGroup = $OrigCheckAGGroup -replace '\[' `
    -replace '\]'

write-host "CheckAGGroup is $($CheckAGGroup)"
write-host "AGroups is $($AGroup)"

    if ($CheckAGGroup -ne $AGroup)
        {write-host "Availability Group $($AGroup) will now be configured"

        New-DbaAvailabilityGroup $Primary -Secondary $secondary -Name $AGroup -EndpointUrl 'TCP://SQL01.contoso.local:5055', 'TCP://sql02.contoso.local:5055' -FailoverMode Automatic -confirm:$false 
        Get-DbaAvailabilityGroup -sqlinstance $Primary -AvailabilityGroup $AGroup | Add-DbaAgReplica -SqlInstance $tertiary -FailoverMode Manual -EndpointUrl 'TCP://sql03.contoso.local:5055' -Confirm:$false
        }

    else {
        write-host "Availability Group $($AGroup) is already configured"
        exit
        }

## Listener
# check for listener
# only one listener allowed
# need to add 2nd IP address and address subnet mask

$CheckAGListener = Get-DbaAgListener -SqlInstance $primary 
    if ($CheckAGListener -ne $false)
        {write-host "Availability Group $($AGroup) already has a Listener Configured. Availability Group Listener $($CheckAGListener) is already configured"      
           }

    else {
      Add-DbaAgListener -sqlInstance $Primary -AvailabilityGroup $AGroup -IPAddress $ListenerIP1 -SubnetMask $ListenerSubnetMask -Name $AGListener -Port 5060

      Write-host "Listener detail is $($agListener)"        
        }











