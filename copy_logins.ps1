# import-module dbatools
Set-DbatoolsInsecureConnection -SessionOnly

$configFile = "C:\replicas.json"
$pathObject = Get-Content -Path $configFile | ConvertFrom-Json 
$list = $pathObject.PSObject.Properties.value

# define the AG name
    $AGLSN = "$($pathobject.listener.name),$($pathobject.listener.port)"

    $primaryReplica = Get-DbaAgReplica -SqlInstance $AGLSN | WHERE ROLE -EQ Primary
    $secondaryReplicas = Get-DbaAgReplica -SqlInstance $AGLSN | Where Role -eq Secondary

$LoginsOnPrimary = (Get-DbaLogin -SqlInstance $primaryReplica.Name)

$list = $pathObject.Secondaries

ForEach ($entry in $list) {

try {

$a = $entry.name
$b = $entry.port
$c = "$($a),$($b)"

     
    $LoginsOnSecondary = (Get-DbaLogin -SqlInstance $c)
    $diff = $LoginsOnPrimary | Where-Object Name -notin ($LoginsOnSecondary.Name)
    if($diff) {
    Copy-DbaLogin -Source $primaryReplica.Name -Destination $c -Login $diff.Name
 }
 }
          
      

catch {
    $msg = $_.Exception.Message
    write-error "Error while synching logins for Availability Group $($AGLSN): $msg"
    }
}