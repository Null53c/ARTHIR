<#
.SYNOPSIS
Get-CBS_Log.ps1 - This will collect the Windows CBS.Log file.  CBS.log is a file which include
logs about components when they get installed or uninstalled during updates

Use the following to record the modules applicability to the MITRE ATT&CK Framework

MITRE ATT&CK Technique IDs: TBD
 
Adjust the variables to what you want to do with each item:
  $ARTHIR_OutputDir 			Set to a directory you want the results of the modules to be stored for harvesting
  $ARTHIR_ReportName			What to name the report used for error checking.  Match this to DOWNLOAD
  $SysName						What you want each report to be pre-pended with such as "computername"
  $WriteEventLogEntry			Create an event log entry that this module ran 'Yes' or 'No'
  $EventSource					The name of the source the event will be written to the Application log (default is ARTHIR)
  $Event_ID						What event ID to use in the log entry
 
  DOWNLOAD						The name of the report you will copy back to the host or launching system, wildcards are acceptable

.NOTES
The DOWNLOAD directive is needed by ARTHIR.ps1 to determine where how to handle
output from this script.  Use the wildcard * to capture the systemname in the report.
 - Example:  C:\Program Files\LMD\Results\*Report_PS_LOG-MD-API-Settings.txt

DOWNLOAD C:\Program Files\ARTHIR\*Report_CBS_Log.txt
#>
$ARTHIR_OutputDir = "C:\Program Files\ARTHIR"
$ARTHIR_ReportName = "Report_CBS_Log.txt"
$SysName = $env:computername
# Create event in Application log
$WriteEventLogEntry = "No"
$EventSource = "ARTHIR"
$Event_ID = "1337"
#
#  Check for report folder existing, or create it
#
if (Test-Path $ARTHIR_OutputDir) {
    Write-Output $ARTHIR_OutputDir "already exists"
 } else {
    new-item $ARTHIR_OutputDir -itemtype directory
    }
#
#  Get the events from the CBS.Log
#
Write-Output "Collecting CBS Log events on $SysName" | Out-File -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "" | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "Timestamp           MessageType LogSource Message" | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Write-Output "-------------------------------------------------------------------" | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
Get-Content $env:windir\logs\CBS\cbs.log | % { 
    $_ -replace "\s\s+", "`t" 
} | % {
    $r = [regex]','
    $r.replace($_, "`t", 1)
} | % {
    $o = "" | Select-Object Timestamp, MessageType, LogSource, Message 
    $o.Timestamp, $o.MessageType, $o.LogSource, $o.Message = ($_ -split "`t").Trim()
    ($o | Format-Table -Autosize -HideTableHeaders | Out-String).Trim() | Out-File -Append -FilePath $ARTHIR_OutputDir\$SysName-$ARTHIR_ReportName
}
#
#  Write log entry
#
If ($WriteEventLogEntry -eq 'No') {
  Break
  }  
  elseif ([System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'CBS Log queried by Arthir'
 }
  else {
    Write-EventLog -LogName Application -EntryType Information -EventId $Event_ID -Source $EventSource -Message 'CBS Log queried by Arthir'
    }
