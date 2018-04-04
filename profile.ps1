#profile

#stores credentials for session
$creds = Get-Credential -Message "dont forget domain" -UserName "administrator@vsphere.local"

#imports required modules
function init{
    $(Get-Date)
    Import-Module VMware.VimAutomation.Core
    Import-Module VMware.VimAutomation.Vds
    Import-Module VMware.VimAutomation.Storage
    Import-Module C:\Users\Administrator\Downloads\powernsx-master\powernsx-master\module\PowerNSX.psm1
    $(Get-Date)
}

#returns the connected vCenter Servers
function servers{
    $global:DefaultVIServers
}

#changes the prompt and colors of CLI
function prompt{
    $console = $Host.UI.RawUI
    $console.ForegroundColor = "white"
    #$Host.PrivateData.ConsolePaneBackgroundColor = "blue"
    #$host.PrivateData.ConsolePaneTextBackgroundColor = "red"
    "justin$ "
}

#attaches VIB to host and scans inventory
function attachVIB{
    param($vib2attach)
    $baseline = Get-Baseline -Name $vib2attach
    $hosts = Get-VMHost
    Attach-Baseline -Entity $hosts -Baseline $baseline
    Scan-Inventory -Entity $hosts
}

#patches the vibs that are specified
function patchVUM{
    param($vc, $cluster, $vib2update)
    $baseline = Get-Baseline -Name $vib2update
    Remediate-Inventory -Server $vc -Entity $cluster -Baseline -Confirm:$false
    #if i wanna run async
    #$hosts = Get-VMHost
    #foreach($item in $hosts){
        #Remediate-Inventory -Server $vc -Entity $item -Baseline -RunAsync -Confirm:$false
    #}
}

#connect to vcenter
function vbc{
    Connect-VIServer vcsa-01a.corp.local -Credential $creds
}

#disconnect from vcenter
function vbd{
    Disconnect-VIServer * -Confirm:$false
}

#enable ssh on specified host
function sshEnable{
    param($hostname)
    Get-VMHostService -VMHost $hostname | Where-Object {$_.Label -eq "ssh"} | Start-VMHostService
}

#boe prox magic get host cert script
function ihella{
    param(
        [parameter(Mandatory=$true)]
        [string] $Destination,
        [parameter()]
        [int]$Port=443
    )
    try{
        $client = New-Object Net.sockets.tcpclient
        $client.Connect($Destination, $Port)
        $stream = $client.GetStream()
        $callback = {Param($sender, $cert, $chain, $errors) return $true}
        $sslstream = [System.Net.Security.SslStream]::new($stream, $true, $callback)
        $sslstream.AuthenticateAsClient('')
        [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($sslstream.RemoteCertificate)
    } catch {
        Write-Warning $_
    } finally {
        $sslstream.Dispose()
        $client.Dispose()
    }
}

#magic cert script wrapped to select the subject
function hellaCerts{
    param($hostname)
    $cert = ihella $hostname
    $cert | select subject
}

#return cert for hosts connected to vc
function stoked{
    if(!$global:DefaultVIServers){
        vbc
    } 
    
    $hosts = Get-VMHost
    foreach($curr in $hosts){
        hellaCerts $curr
    }
}

#return host and ID
function hostID{
    Get-VMHost | select id, name
}

#return datastores that the vc can see
function getDatastores{
    #$errorFile = "error.csv"
    Write-Output "===================="
    Write-Output "started checking datastores"

    if(!$global:DefaultVIServers){
        vbc
    } 
    Get-Datastore | select name, capacitygb | Export-Csv datastores.csv -NoTypeInformation -Append
    vbd

    Write-Output "finished checking datastores"
    Write-Output "===================="
}

#returns the datastores and storage on each host
function getHostDatastores{
    Write-Output "===================="
    Write-Output "started checking datastores per host"

    if(!$global:DefaultVIServers){
        vbc
    } 
    $hosts = Get-VMHost
    foreach($curr in $hosts){
        Get-Datastore | select name, capacitygb | Export-Csv hostDatastores.csv -NoTypeInformation -Append
        $curr.Name | Out-File hostDatastores.csv -Append
        #" " | Out-File hostDatastores.csv -Append
        #" " | Out-File hostDatastores.csv -Append
    }
    vbd

    Write-Output "finished checking datastores per host"
    Write-Output "===================="
}

#returns the virtual distribtued switch and settings
function getVDS{
    Write-Output "===================="
    Write-Output "started checking virtual distributed switches and number of ports"

    if(!$global:DefaultVIServers){
        vbc
    } 
    Get-VDPortgroup | select name, virtualswitch, numports | export-csv vds.csv -NoTypeInformation -Append 
    vbd

    Write-Output "finished checking virtual distributed switches and number of ports"
    Write-Output "===================="
}

#returns the location the host is sending syslogs to
function getLogsLocation{
    Write-Output "===================="
    Write-Output "started checking syslog.global.loghost location"

    if(!$global:DefaultVIServers){
        vbc
    } 
    $hosts = Get-VMHost
    foreach($curr in $hosts){
        Get-VMHostSysLogServer $curr | Export-Csv logAddr.csv -NoTypeInformation -Append
        $curr.Name | Out-File logAddr.csv -Append
        #" " | Out-File logAddr.csv -Append
        #" " | Out-File logAddr.csv -Append
    }

    vbd

    Write-Output "finished checking syslog.global.loghost location"
    Write-Output "===================="
}

#returns the domain the host is connected to if any
function getDomain{
    Write-Output "===================="
    Write-Output "started checking domain"

    if(!$global:DefaultVIServers){
        vbc
    } 
    $hosts = Get-VMHost
    foreach($curr in $hosts){
        $result = Get-VMHostAuthentication -VMHost $curr
        $result | select domain | Out-File domains.csv -Append
        $curr.Name | Out-File domains.csv -Append
        #" " | Out-File domains.csv -Append
        #" " | Out-File domains.csv -Append
    }
    vbd

    Write-Output "finished checking domain"
    Write-Output "===================="
}

#returns the physical uplinks for each host
function getPhysUplinksHost{
    Write-Output "===================="
    Write-Output "started checking physical uplinks per host"

    if(!$global:DefaultVIServers){
        vbc
    } 
    $hosts = Get-VMHost
    foreach($curr in $hosts){
        Get-VMHostNetworkAdapter -VMHost $curr -Physical | select vmhost, name, bitratepersec | Export-Csv physicalUplinksPerHost.csv -NoTypeInformation -Append
        " " | Out-File physicalUplinksPerHost.csv -Append
        " " | Out-File physicalUplinksPerHost.csv -Append
    }
    vbd

    Write-Output "finished checking physical uplinks per host"
    Write-Output "===================="
}

#returns the HA, DRS and EVC status for each host
function getHAandDRSandEVC{
    Write-Output "===================="
    Write-Output "started checking HA DRS EVC"

    if(!$global:DefaultVIServers){
        vbc
    } 
    Get-Cluster | Select-Object -Property name, haenabled,drsenabled, evcmode | Export-Csv hadrsevc.csv -NoTypeInformation -Append
    vbd

    Write-Output "finished checking HA DRS EVC"
    Write-Output "===================="
}

#returns the ntp server for each host
function getNTP{
Write-Output "===================="
    Write-Output "started checking NTP"

    if(!$global:DefaultVIServers){
        vbc
    } 
    $hosts = Get-VMHost
    foreach($curr in $hosts){
        $curr | Get-VMHostNtpServer | Out-File ntp.csv -Append
        $curr.Name | Out-File ntp.csv -Append
        " " | Out-File ntp.csv -Append
    }
    vbd

    Write-Output "finished checking NTP"
    Write-Output "===================="
}

#returns the current path ie  PWD
function getPath{
    pwd
}


















