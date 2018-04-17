<#
.Synopsis
   This script is to Transpose csv table data from rows to columns.
.DESCRIPTION
   This script allows you to import a csv file and transpose the data inside just like you do it in Excel, with some limitations.
   Its irrespective of the length and size of the table. It automatically calculates and switches the rows to columns.
   Output is PSCustomObject that can be manipulated just like any other PSObject, Export-CSV or ft, fl etc.
   The view would not make much sense in console output, but when checked in Excel it would make lots of sense.
   
   Mainly on data that has less objects\rows and more columins\parameters. Transpose would make it look cleaner.

   #The logic behind is slightly tricky, if you still want to know read through:
   1.Csv file is imported and current headers extracted.
   2.First element of the header and all the corresponding values for that parameter is used as input for new PS Object header
   3.2nd element of header and remaining old header info forms the first column\entry of the new objects
   4.The other values are also similarly placed after one another
   5.All the objects are collected in an array and moved out.

   Errors\Troublshooting:
   *This script requires you to have atleast PowerShell V3.0 onwards to run as it utilizes many features introduced in v3.
   *Make sure there is data in the Header and the First Column is filled, if blank it will throw error.
   *Make sure there is no duplicate data in the header and the first column. They must be unique.

   @Author: Satyajit Aug 2015

.EXAMPLE
   .\Transpose.ps1 | ft

.EXAMPLE
   Example of how to use this cmdlet
   .\Transpose.ps1 -InputFile .\ProcessData.csv | ft
.EXAMPLE
   Another example of how to use this cmdlet
   .\Transpose.ps1

.EXAMPLE
This is how the original and converted data looks like.

PS Transpose> Import-Csv .\ProcessData.csv

Name                                 Status                               DisplayName
----                                 ------                               -----------
p2pimsvc                             Stopped                              Peer Networking Identity Manager
p2psvc                               Stopped                              Peer Networking Grouping
PcaSvc                               Running                              Program Compatibility Assistant
PeerDistSvc                          Running                              BranchCache
PerfHost                             Stopped                              Performance Counter DLL Host
pla                                  Stopped                              Performance Logs & Alerts


PS Transpose> .\Transpose.ps1 -InputFile .\ProcessData.csv | ft

Name       p2pimsvc   p2psvc     PcaSvc     PeerDistSv PerfHost   pla
                                            c

----       --------   ------     ------     ---------- --------   ---
Status     Stopped    Stopped    Running    Running    Stopped    Stopped
Display... Peer Ne... Peer Ne... Program... BranchC... Perform... Perform...

PS Transpose> .\Transpose.ps1 -InputFile .\ProcessData.csv | fl


Name             : Status
p2pimsvc         : Stopped
p2psvc           : Stopped
PcaSvc           : Running
PeerDistSvc      : Running
PerfHost         : Stopped
pla              : Stopped

Name             : DisplayName
p2pimsvc         : Peer Networking Identity Manager
p2psvc           : Peer Networking Grouping
PcaSvc           : Program Compatibility Assistant Service
PeerDistSvc      : BranchCache
PerfHost         : Performance Counter DLL Host
pla              : Performance Logs & Alerts

.EXAMPLE
Use this example to export the transposed data back to a CSV, without type details.

.\Transpose.ps1 -InputFile .\ProcessData.csv | Export-Csv ProcessDataT2.csv  -NoTypeInformation
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
    (
        #Custom input file name, default is "ProcessData.csv" in current directory
        [Parameter(Mandatory=$false,
                   Position=0)]
        $InputFile = "ProcessData.csv"

        
    )




#Extracting header info from CSV file
$pdata = Import-Csv $InputFile
$header = $pdata[0].psobject.properties.name

#$header[0]

$pdataT = New-Object –TypeName PSObject


#Transposing the data

#Creating the object
foreach ($para in $header)
{

#Find current position
#$header.IndexOf($para))

$pdataT | Add-Member –MemberType NoteProperty –Name $para -Value $null

    foreach ($obj in $pdata)
    {
    
    $pdataT | Add-Member –MemberType NoteProperty –Name $obj.$($para) -Value $null

 #$obj.$($para)
    }

  #Breaking as taking only first column data as rows\parameter
  break
        
}




#Extracting new header info
$newHeader = $pdataT[0].psobject.properties.name

#Blank array for result
$objResult = @()


# Value filling
foreach ($para in $Header)
 {

#Creating new object for every item
$objTemp = $pdataT | Select-Object *
  
  #Skipping the first column of old data, which is already header.
  if($header.IndexOf($para) -eq 0){continue}

  #First obj to be fillup by old header data
  $i = 0
  $objTemp.$($newHeader[$i]) = $para
          
   foreach ($obj2 in $pdata)
    {
    
    $i = $pdata.IndexOf($obj2) + 1
 
    #"$($newHeader[$i]) = $($obj2.Status)"
    $objTemp.$($newHeader[$i]) = $obj2.$para
    
    }

  #  $objResult += $pdataT
  #$objTemp | ft
  #Adding the objects to array
  $objResult += $objTemp
 }

 Write-Output $objResult
 