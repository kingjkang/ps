#profile

#stores credentials for session
$creds = Get-Credential -Message "dont forget domain password is classic" -UserName "administrator@vsphere.local"

#imports required modules
function init{
    Write-Output "Importing modules"
    $date1 = $(Get-Date)
    Import-Module VMware.VimAutomation.Core
    Import-Module VMware.VimAutomation.Vds
    Import-Module VMware.VimAutomation.Storage
    Import-Module C:\Users\Administrator\Downloads\powernsx-master\powernsx-master\module\PowerNSX.psm1
    $date2 = $(Get-Date)
    $time = $date2 - $date1
    #$time = $time | select seconds
    Write-Output "Importing modules took $($time.seconds) seconds."
}

#returns the connected vCenter Servers
function servers{
    if(!$global:DefaultVIServers){
        Write-Output "You are not connected to any vCenter Servers"
    } else {
        #$global:DefaultVIServers
        foreach($server in $global:DefaultVIServers){
            Write-Output "You are connected to $($server.Name)"
        }
    }
}

#returns the connected vCenter Servers with details
function serversDetailed{
    if(!$global:DefaultVIServers){
        Write-Output "You are not connected to any vCenter Servers"
    } else {
        #$global:DefaultVIServers
        foreach($server in $global:DefaultVIServers){
            Write-Output "You are connected to $($server.Name) as $($server.User) through port $($server.Port)"
        }
    }
}

#changes the prompt and colors of CLI
function prompt{
    $console = $Host.UI.RawUI
    $console.ForegroundColor = "magenta"
    $Host.PrivateData.ConsolePaneBackgroundColor = "darkblue"
    $host.PrivateData.ConsolePaneTextBackgroundColor = "darkblue"
    $currPath = pwd
    #"$($currPath) justin$ "
    $vis = " $($global:DefaultVIServers.name) "
    "$($currPath)$($vis)justin$ "
}

#attaches VIB to host and scans inventory
function attachVIB{
    param($vib2attach)
    Write-Output "Attaching VIB $($vib2attach)"
    $baseline = Get-Baseline -Name $vib2attach
    $hosts = Get-VMHost
    Attach-Baseline -Entity $hosts -Baseline $baseline
    Write-Output "Completed attaching VIB $($vib2attach)"
    Write-Output "Re-scanning inventory for compliance"
    Scan-Inventory -Entity $hosts
    Write-Output "Completed re-scanning inventory for compliance"
}

#patches the vibs that are specified
function patchVUM{
    param($vc, $cluster, $vib2update)
    Write-Output "Starting patch of $($vib2update) on cluster $($cluster)"
    $baseline = Get-Baseline -Name $vib2update
    Remediate-Inventory -Server $vc -Entity $cluster -Baseline -Confirm:$false
    Write-Output "Completed patch of $($vib2update) on cluster $($cluster)"
    #if i wanna run async
    #$hosts = Get-VMHost
    #foreach($item in $hosts){
        #Remediate-Inventory -Server $vc -Entity $item -Baseline -RunAsync -Confirm:$false
    #}
}

#connect to vcenter
function vbc{
    Write-Output "Connecting to vcsa-01a.corp.local"
    $vc = Connect-VIServer vcsa-01a.corp.local -Credential $creds
    servers
}

#disconnect from vcenter
function vbd{
    servers
    Write-Output "Disconnecting from vcsa-01a.corp.local"
    Disconnect-VIServer * -Confirm:$false
    servers
}

#enable ssh on specified host
function sshEnable{
    param($hostname)
    Write-Output "Enabling SSH on $($hostname)"
    $enabled = Get-VMHostService -VMHost $hostname | Where-Object {$_.Label -eq "ssh"} | Start-VMHostService
    if($enabled.Running){
        Write-Output "Enabled SSH on $($hostname)"
    } else {
        Write-Output "Failed to enable SSH on $($hostname)"
    }
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
    param($hostname)

    if(!$global:DefaultVIServers){
        vbc
    } 
    
    Write-Output "Starting to obtaining host Ccrtificates"
    if($hostname){
        hellaCerts $hostname
    } else {
        $hosts = Get-VMHost
        foreach($curr in $hosts){
            hellaCerts $curr
        }
    }
    Write-Output " "
    Write-Output "Completed obtaining host certificates"
}

#return host and ID
function hostID{
    Write-Output "Getting hosts and their ID's"
    Get-VMHost | select id, name
    Write-Output " "
    Write-Output "Completed getting hosts and their ID's"
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
    Write-Output "Writing output to $(pwd)\datastores.csv"
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
    Write-Output "Writing output to $(pwd)\hostDatastores.csv"
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
    Write-Output "Writing output to $(pwd)\vds.csv"
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
    Write-Output "Writing output to $(pwd)\logAddr.csv"
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
    Write-Output "Writing output to $(pwd)\domains.csv"
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
    Write-Output "Writing output to $(pwd)\physicalUplinksPerHost.csv"
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
    Write-Output "Writing output to $(pwd)\hadrsevc.csv"
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
    Write-Output "Writing output to $(pwd)\ntp.csv"
}

#returns the current path ie  PWD
function getPath{
    #pwd
    $currentDirectory = pwd
    Write-Output "$($currentDirectory)"
}


















