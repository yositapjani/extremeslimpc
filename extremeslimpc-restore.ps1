<#
ExtremeSlimPC - Restore script.
Undoes extremeslimpc.ps1 as far as Windows allows:
  - Re-enables the 14 services (DiagTrack, MapsBroker, CDPUserSvc back to
    Automatic; the rest back to Manual) and tries to start them
  - Re-enables the 8 scheduled tasks (tries both Appraiser task names)
  - Removes the policy values (Windows defaults return), restores
    ContentDeliveryAllowed/SilentInstalledAppsEnabled to 1 and
    location consent to Allow
What it does NOT do:
  - It does NOT reinstall removed Store apps. Reinstall them from the
    Microsoft Store (the Store itself was never removed).
  - It does NOT reinstall OneDrive. Run this manually if you want it back:
      $env:SystemRoot\System32\OneDriveSetup.exe
Run in Windows PowerShell as Administrator:
  irm https://raw.githubusercontent.com/yositapjani/extremeslimpc/main/extremeslimpc-restore.ps1 | iex
Reboot recommended after restore.
#>
$ErrorActionPreference = 'Continue'
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Output 'ERROR: Run this script as Administrator.'
  return
}
Write-Output 'EXTREMESLIMPC-RESTORE-START'
Write-Output '=== SERVICES RESTORE ==='
$autoSvc = @('DiagTrack', 'MapsBroker', 'CDPUserSvc')
$manualSvc = @('dmwappushservice', 'lfsvc', 'OneSyncSvc', 'PimIndexMaintenanceSvc', 'UnistoreSvc', 'UserDataSvc', 'wisvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'XboxGipSvc')
foreach ($n in $autoSvc) {
  try {
    Set-Service -Name $n -StartupType Automatic -ErrorAction Stop
    Start-Service -Name $n -ErrorAction SilentlyContinue
    $after = Get-Service -Name $n -ErrorAction SilentlyContinue
    Write-Output ("SVC-RESTORED: {0} Status={1} Start={2}" -f $n, $after.Status, $after.StartType)
  } catch { Write-Output ("SVC-FAILED: {0} {1}" -f $n, $_.Exception.Message) }
}
foreach ($n in $manualSvc) {
  try {
    Set-Service -Name $n -StartupType Manual -ErrorAction Stop
    $after = Get-Service -Name $n -ErrorAction SilentlyContinue
    Write-Output ("SVC-RESTORED: {0} Status={1} Start={2}" -f $n, $after.Status, $after.StartType)
  } catch { Write-Output ("SVC-FAILED: {0} {1}" -f $n, $_.Exception.Message) }
}
Write-Output '=== TASKS RESTORE ==='
$enableTasks = @('\Microsoft\Windows\Customer Experience Improvement Program\|Consolidator', '\Microsoft\Windows\Customer Experience Improvement Program\|UsbCeip', '\Microsoft\Windows\Application Experience\|Microsoft Compatibility Appraiser', '\Microsoft\Windows\Application Experience\|Microsoft Compatibility Appraiser Exp', '\Microsoft\Windows\Application Experience\|PcaPatchDbTask', '\Microsoft\Windows\Application Experience\|StartupAppTask', '\Microsoft\Windows\Location\|WindowsActionDialog', '\Microsoft\Windows\Maps\|MapsToastTask', '\Microsoft\Windows\DiskDiagnostic\|Microsoft-Windows-DiskDiagnosticDataCollector')
foreach ($pair in $enableTasks) {
  $parts = $pair.Split('|')
  $tp = $parts[0]
  $tn = $parts[1]
  try {
    Enable-ScheduledTask -TaskPath $tp -TaskName $tn -ErrorAction Stop | Out-Null
    Write-Output ("TASK-ENABLED: {0}{1}" -f $tp, $tn)
  } catch { Write-Output ("TASK-FAILED: {0}{1} {2}" -f $tp, $tn, $_.Exception.Message) }
}
Write-Output '=== REGISTRY RESTORE ==='
function Remove-Reg($path, $name) {
  try {
    Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction Stop
    Write-Output ("REG-REMOVED: {0} {1}" -f $path, $name)
  } catch { Write-Output ("REG-FAILED: {0} {1} {2}" -f $path, $name, $_.Exception.Message) }
}
function Set-Reg($path, $name, $value, $type) {
  try {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction Stop | Out-Null }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
    Write-Output ("REG-SET: {0} {1} = {2}" -f $path, $name, $value)
  } catch { Write-Output ("REG-FAILED: {0} {1} {2}" -f $path, $name, $_.Exception.Message) }
}
Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry'
Remove-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry'
Remove-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled'
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'Allow' 'String'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 1 'DWord'
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 1 'DWord'
Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed'
Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana'
Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC'
Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode'
Remove-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures'
Remove-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled'
Remove-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent'
Remove-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled'
Write-Output 'EXTREMESLIMPC-RESTORE-DONE'
Write-Output 'Reboot recommended. Removed Store apps must be reinstalled from the Microsoft Store.'
Write-Output 'To reinstall OneDrive manually, run: $env:SystemRoot\System32\OneDriveSetup.exe'
